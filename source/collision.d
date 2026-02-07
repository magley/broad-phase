module collision;

import entity;
import rect;
import std.algorithm;
import std.algorithm.sorting;
import std.array;
import std.datetime.stopwatch;
import std.stdio;
import std.string;
import std.typecons;
import vector;
import vendor.sdl;

struct CollisionResult
{
    Entity e1, e2;
}

class Collision
{
    enum Type
    {
        None,
        Naive,
        GridHash,
        SortAndSweep,
        QuadTree,
        RTree,
    }

    Type type = Type.None;

    CollisionResult[] update(Entity[] e, SDL_Renderer* rend)
    {
        final switch (type) with (Type)
        {
        case None:
            return update_none(e, rend);
        case Naive:
            return update_naive(e, rend);
        case GridHash:
            return update_grid_hash(e, rend);
        case SortAndSweep:
            return update_sort_and_sweep(e, rend);
        case QuadTree:
            return update_quad_tree(e, rend);
        case RTree:
            return update_r_tree(e, rend);
        }
    }

    private CollisionResult[] update_none(Entity[] entities, SDL_Renderer* rend)
    {
        return [];
    }

    private CollisionResult[] update_naive(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;

        for (int i = 0; i < entities.length; i++)
        {
            for (int j = i + 1; j < entities.length; j++)
            {
                Entity e1 = entities[i];
                Entity e2 = entities[j];

                if (e1.intersect(e2))
                {
                    result ~= CollisionResult(e1, e2);
                }
            }
        }

        return result;
    }

    private CollisionResult[] update_grid_hash(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;
        const vec2 cell = vec2(50, 50);

        ulong hash(vec2 point, vec2 cell) => (point / cell).floor().toHash();

        // Build buckets
        Entity[][ulong] buckets;
        foreach (Entity e; entities)
        {
            const box2 rect = e.bbox();

            bool[ulong] pointset;
            pointset[hash(rect.ul, cell)] = true;
            pointset[hash(rect.ur, cell)] = true;
            pointset[hash(rect.dl, cell)] = true;
            pointset[hash(rect.dr, cell)] = true;

            foreach (ulong k, _; pointset)
            {
                buckets[k] ~= e;
            }
        }

        // Collision within buckets

        bool[Tuple!(size_t, size_t)] pairs;

        foreach (_, Entity[] bucket; buckets)
        {
            for (int i = 0; i < bucket.length; i++)
            {
                for (int j = i + 1; j < bucket.length; j++)
                {
                    Entity e1 = bucket[i];
                    Entity e2 = bucket[j];

                    auto t = tuple(e1.id, e2.id);

                    if (t in pairs)
                        continue;
                    pairs[t] = true;

                    if (e1.intersect(e2))
                    {
                        result ~= CollisionResult(e1, e2);
                    }
                }
            }
        }

        // Draw grid
        SDL_SetRenderDrawColorFloat(rend, 1, 1, 0, 1);
        for (float x = 0 - cell.x; x <= 800 + cell.x; x += cell.x)
        {
            SDL_RenderLine(rend, x, -100, x, 600 + 100);
        }
        for (float y = 0 - cell.y; y <= 600 + cell.y; y += cell.y)
        {
            SDL_RenderLine(rend, -100, y, 800 + 100, y);
        }

        return result;
    }

    private CollisionResult[] update_sort_and_sweep(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;

        struct SweepPoint
        {
            float val;
            size_t index;
            bool isMini;
        }

        SweepPoint[] points;

        // Sort

        reserve(points, entities.length * 2);
        foreach (size_t i, Entity e; entities)
        {
            points ~= SweepPoint(e.bbox.left, i, true);
            points ~= SweepPoint(e.bbox.right, i, false);
        }
        points = sort!"a.val < b.val"(points).array();

        // Sweep

        size_t[] set;
        foreach (ref SweepPoint p; points)
        {
            if (p.isMini)
            {
                foreach (size_t eIndex; set)
                {
                    Entity e1 = entities[p.index];
                    Entity e2 = entities[eIndex];

                    if (e1.intersect(e2))
                    {
                        result ~= CollisionResult(e1, e2);
                    }
                }

                set ~= p.index;
            }
            else
            {
                int i = 0;
                for (int j = 0; j < set.length; j++)
                {
                    if (set[j] == p.index)
                    {
                        i = j;
                        break;
                    }
                }
                set = set[0 .. i] ~ set[i + 1 .. $];
            }
        }

        return result;
    }

    private CollisionResult[] update_quad_tree(Entity[] entities, SDL_Renderer* rend)
    {
        struct QuadNode
        {
            QuadNode*[4] child;
            box2 area;
            int capacity;

            size_t[] items;

            this(box2 area, int capacity)
            {
                this.area = area;
                this.capacity = capacity;
            }

            void insert(size_t id)
            {
                // Leaf node: insert if not present if capacity surpassed then
                // split and reinsert to children.
                if (child[0] is null)
                {
                    foreach (size_t j; items)
                    {
                        if (j == id)
                            return;
                    }

                    items ~= id;
                    if (items.length > capacity && (area.size.x > 50 && area.size.y > 50))
                    {
                        split();

                        foreach (size_t i; items)
                            insert(i);
                        items = [];
                    }
                }
                // Non-leaf node: for each edge point of bbox, insert to the
                // corresponding child.
                else
                {
                    Entity e = entities[id];
                    box2 eRect = e.bbox();

                    vec2[] edges = [
                        eRect.ul,
                        eRect.ur,
                        eRect.dl,
                        eRect.dr,
                    ];
                    bool[4] used = [false, false, false, false];

                    foreach (vec2 v; edges)
                    {
                        size_t ci = child_index(v);
                        if (used[ci])
                            continue;
                        used[ci] = true;
                        child[ci].insert(id);
                    }
                }
            }

            size_t[][] get_buckets()
            {
                size_t[][] res;

                if (child[0] == null)
                {
                    return [items];
                }

                foreach (int i; 0 .. 4)
                {
                    res ~= child[i].get_buckets();
                }

                return res;
            }

            void draw()
            {
                SDL_FRect rect = SDL_FRect(area.x, area.y, area.w, area.h);
                SDL_SetRenderDrawColorFloat(rend, 1.0, 1.0, 0.0, 1.0);
                SDL_RenderRect(rend, &rect);
                if (child[0]!is null)
                {
                    child[0].draw();
                    child[1].draw();
                    child[2].draw();
                    child[3].draw();
                }
            }

            private void split()
            {
                child[0] = new QuadNode(box2.pos_sz(area.ul + area.size * vec2(0, 0) / 2, area.size / 2), capacity);
                child[1] = new QuadNode(box2.pos_sz(area.ul + area.size * vec2(1, 0) / 2, area.size / 2), capacity);
                child[2] = new QuadNode(box2.pos_sz(area.ul + area.size * vec2(0, 1) / 2, area.size / 2), capacity);
                child[3] = new QuadNode(box2.pos_sz(area.ul + area.size * vec2(1, 1) / 2, area.size / 2), capacity);
            }

            private size_t child_index(vec2 point)
            {
                size_t i = 0;
                if (point.x > child[0].area.right)
                    i += 1;
                if (point.y >= child[0].area.bottom)
                    i += 2;

                return i;
            }
        }

        CollisionResult[] result;

        QuadNode* root = new QuadNode(box2.uldr(vec2(0, 0), vec2(800, 600)), 5);
        foreach (size_t i, Entity e; entities)
        {
            root.insert(i);
        }
        root.draw();

        bool[Tuple!(size_t, size_t)] seen;

        foreach (size_t[] bucket; root.get_buckets())
        {
            for (int i = 0; i < bucket.length; i++)
            {
                for (int j = i + 1; j < bucket.length; j++)
                {
                    if (bucket[i] > bucket[j])
                        continue;
                    auto t = tuple(bucket[i], bucket[j]);
                    if (t in seen)
                        continue;
                    seen[t] = true;

                    Entity e1 = entities[bucket[i]];
                    Entity e2 = entities[bucket[j]];

                    if (e1.intersect(e2))
                    {
                        result ~= CollisionResult(e1, e2);
                    }
                }
            }
        }

        return result;
    }

    private CollisionResult[] update_r_tree(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;

        const size_t B = 50;

        struct RNode
        {
            RNode*[B] child;
            RNode* parent = null;
            box2 area;
            size_t[] items;

            bool is_leaf() const => child[0] == null;

            this(box2 area)
            {
                foreach (RNode* n; child)
                    n = null;
                items = [];
                this.area = area;
            }

            void insert(size_t id)
            {
                if (is_leaf)
                {
                    items ~= id;
                    if (items.length > B)
                    {
                        handle_overflow();
                    }
                }
                else
                {
                    RNode* n = find(id);
                    assert(n !is null);
                    n.insert(id);
                }
            }

            RNode* find(size_t id)
            {
                const box2 bbox = entities[id].bbox();

                RNode* best = null;
                box2 best_rect;

                foreach (RNode* n; child)
                {
                    const box2 rect = n.area.expand_to_contain(bbox);

                    if (best == null ||
                        rect.perimiter < best_rect.perimiter ||
                        (rect.perimiter == best_rect.perimiter && rect.area < best_rect.area))
                    {
                        best = n;
                        best_rect = rect;
                    }
                }

                return best;
            }

            private void handle_overflow()
            {
                /*
                split items into nodes a, b
                make a and b children...
    
                */

            }
        }

        return result;
    }
}

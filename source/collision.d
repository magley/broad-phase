module collision;

import entity;
import input;
import rect;
import std.algorithm;
import std.algorithm.sorting;
import std.array;
import std.datetime.stopwatch;
import std.math;
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
    Input* input;

    this(Input* input)
    {
        this.input = input;
    }

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
        SDL_SetRenderDrawColorFloat(rend, 1, 0, 0, 1);
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
                SDL_SetRenderDrawColorFloat(rend, 1.0, 0.0, 0.0, 1.0);
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
        const size_t Bmin = cast(int)(0.4 * B);

        static int subtype = 0;

        if (input.key_press(SDL_SCANCODE_Q))
        {
            subtype = (subtype + 1) % 3;
        }

        class RNode
        {
            RNode[] child;
            RNode parent = null;
            box2 area;
            size_t[] items;

            bool is_leaf() const => child.length == 0;
            bool is_root() const => parent is null;

            RNode get_root() const
            {
                if (is_root)
                    return cast(RNode) this;
                return parent.get_root();
            }

            void draw()
            {
                SDL_FRect rect = SDL_FRect(area.x, area.y, area.w, area.h);
                SDL_SetRenderDrawColorFloat(rend, 1.0, 0.0, 0.0, 1.0);
                SDL_RenderRect(rend, &rect);
                foreach (RNode c; child)
                {
                    c.draw();
                }
            }

            this(box2 area)
            {
                child = [];
                items = [];
                this.area = area;
            }

            void insert(size_t id)
            {
                if (is_leaf())
                {
                    items ~= id;
                    if (items.length > B)
                    {
                        handle_overflow();
                    }
                }
                else
                {
                    RNode n = find(id);
                    assert(n !is null);
                    n.insert(id);
                    area = area.expand_to_contain(entities[id].bbox());
                }
            }

            RNode find(size_t id)
            {
                const box2 bbox = entities[id].bbox();

                RNode best = null;
                box2 best_rect;

                foreach (RNode n; child)
                {
                    const box2 rect = n.area.expand_to_contain(bbox);

                    if (best is null ||
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
                SplitResult t;
                if (subtype == 0)
                    t = split_classic(true);
                if (subtype == 1)
                    t = split_classic(false);
                if (subtype == 2)
                    t = split_sortapprox();

                size_t[] items1 = t.items1;
                box2 mbr1 = t.bbox1;
                size_t[] items2 = t.items2;
                box2 mbr2 = t.bbox2;

                this.area = mbr1;
                this.items = items1;
                RNode newnode = new RNode(mbr2);
                newnode.items = items2;

                if (is_root())
                {
                    RNode newroot = new RNode(mbr1.expand_to_contain(mbr2));

                    RNode[] nodes = [cast(RNode) this, newnode];
                    foreach (RNode n; nodes)
                    {
                        n.parent = newroot;
                        newroot.child ~= n;
                    }
                }
                else
                {
                    RNode[] nodes = [newnode]; // `this` is redundant
                    foreach (RNode n; nodes)
                    {
                        n.parent = parent;
                        parent.child ~= n;
                    }
                    if (parent.child.length > B)
                    {
                        parent.handle_overflow();
                    }
                }
            }

            struct SplitResult
            {
                size_t[] items1;
                box2 bbox1;
                size_t[] items2;
                box2 bbox2;
            }

            private SplitResult split_classic(bool linear = false)
            {
                // Find two furthest bboxes

                size_t[] items1, items2;
                box2 bbox1, bbox2;

                if (linear)
                {
                    float maxdist = 0;
                    for (int i = 0; i < items.length; i++)
                    {
                        const box2 b1 = entities[items[i]].bbox;
                        for (int j = i + 1; j < items.length; j++)
                        {
                            const box2 b2 = entities[items[j]].bbox;
                            const float distx = b1.dist_x(b2);
                            const float disty = b1.dist_y(b2);
                            const float dist = max(distx, disty);

                            if (dist >= maxdist)
                            {
                                maxdist = dist;
                                bbox1 = b1;
                                bbox2 = b2;
                                items1 = [items[i]];
                                items2 = [items[j]];
                            }
                        }
                    }
                }
                else
                {
                    float max_waste = 0;

                    for (int i = 0; i < items.length; i++)
                    {
                        const box2 b1 = entities[items[i]].bbox;
                        for (int j = i + 1; j < items.length; j++)
                        {
                            const box2 b2 = entities[items[j]].bbox;
                            const float waste = b1.expand_to_contain(b2).area - (b1.area + b2.area);

                            if (waste >= max_waste)
                            {
                                max_waste = waste;
                                bbox1 = b1;
                                bbox2 = b2;
                                items1 = [items[i]];
                                items2 = [items[j]];
                            }
                        }
                    }
                }

                // For other boxes, greedily pick based on increase in area.

                size_t p1 = items1[0];
                size_t p2 = items2[0];

                foreach (size_t i; items)
                {
                    if (i == p1 || i == p2)
                        continue;
                    box2 b = entities[i].bbox;

                    box2 bbox1_ex = bbox1.expand_to_contain(b);
                    box2 bbox2_ex = bbox2.expand_to_contain(b);

                    if ((bbox1_ex.area - bbox1.area) < (bbox2_ex.area - bbox2.area))
                    {
                        items1 ~= i;
                        bbox1 = bbox1_ex;
                    }
                    else
                    {
                        items2 ~= i;
                        bbox2 = bbox2_ex;
                    }
                }

                box2 compute_mbr(size_t[] group)
                {
                    box2 bbox = entities[group[0]].bbox;
                    foreach (size_t id; group[1 .. $])
                    {
                        bbox = bbox.expand_to_contain(entities[id].bbox);
                    }
                    return bbox;
                }

                bbox1 = compute_mbr(items1);
                bbox2 = compute_mbr(items2);

                return SplitResult(items1, bbox1, items2, bbox2);
            }

            private SplitResult split_sortapprox()
            {
                // https://www.cse.cuhk.edu.hk/~taoyf/course/infs4205/lec/rtree.pdf

                // Sort all items.

                bool less(size_t a, size_t b) => entities[a].bbox.left < entities[b].bbox.left;
                size_t[] sorted = sort!less(items).array;
                const size_t N = items.length;
                box2 mbr_containing_entities(size_t[] arr)
                {
                    box2 bbox;
                    foreach (size_t item; arr)
                        bbox = bbox.expand_to_contain(entities[item].bbox);
                    return bbox;
                }

                // Sliding window, use one with smallest perimiter sum.

                size_t[] best1, best2;
                box2 bestmbr1, bestmbr2;
                float best_perimiter = -1;

                for (size_t i = Bmin; i < N - Bmin; i++)
                {
                    size_t[] set1 = sorted[0 .. i];
                    box2 mbr1 = mbr_containing_entities(set1);

                    size_t[] set2 = sorted[i .. N];
                    box2 mbr2 = mbr_containing_entities(set2);

                    float perimiter = mbr1.perimiter + mbr2.perimiter;
                    if (best_perimiter == -1 || (perimiter < best_perimiter))
                    {
                        best_perimiter = perimiter;
                        best1 = set1;
                        best2 = set2;
                        bestmbr1 = mbr1;
                        bestmbr2 = mbr2;
                    }
                }

                return SplitResult(best1, bestmbr1, best2, bestmbr2);
            }
        }

        RNode rtree = new RNode(entities[0].bbox);

        foreach (size_t index, Entity e; entities)
        {
            rtree.insert(index);
        }
        rtree = rtree.get_root();
        rtree.draw();

        return result;
    }
}

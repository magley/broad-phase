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

        const size_t B = 100;

        class RNode
        {
            box2 bounds;
            RNode[] children;
            RNode parent;
            size_t[] items;

            bool is_leaf() const => children.length == 0;
            bool is_root() const => parent is null;

            this(box2 bounds)
            {
                this.bounds = bounds;
            }

            RNode get_root() const
            {
                RNode n = cast(RNode) this;
                while (!n.is_root())
                    n = n.parent;
                return n;
            }

            void draw() const
            {
                SDL_SetRenderDrawColorFloat(rend, 1, 0, 0, 1);
                SDL_FRect rect = bounds.sdlrect();
                SDL_RenderRect(rend, &rect);
                foreach (const(RNode) child; children)
                    child.draw();
            }

            void insert(size_t item)
            {
                const box2 bbox = entities[item].bbox();
                RNode node = choose_leaf(bbox);
                node.items ~= item;

                const bool overflow = node.items.length > B;

                if (!overflow)
                {
                    node.update_bounds(true);
                }
                else
                {
                    node.handle_overflow();
                }
            }

            /// Find all items which are candidates for intersection with `bbox`.
            size_t[] query(const box2 bbox)
            {
                if (is_leaf && bbox.intersect_inc(bounds))
                {
                    return items;
                }

                size_t[] result;
                foreach (RNode child; children)
                {
                    result ~= child.query(bbox);
                }
                return result;
            }

            /// Update bounding boxes of this node (and parent nodes if recursion is set to `true`).
            private void update_bounds(bool recurse_up)
            {
                if (is_leaf && items.length > 0)
                {
                    bounds = entities[items[0]].bbox;
                    foreach (size_t item; items[1 .. $])
                        bounds = bounds.expand_to_contain(entities[item].bbox);
                }
                else if (!is_leaf && children.length > 0)
                {
                    bounds = children[0].bounds;
                    foreach (RNode child; children[1 .. $])
                        bounds = bounds.expand_to_contain(child.bounds);
                }
                if (recurse_up && !is_root)
                    parent.update_bounds(true);
            }

            /// Sect leaf node with least enlargement to include bbox.
            /// Params:
            ///   bbox = Bounding box of the object to insert into the tree.
            /// Returns: The best leaf node.
            private RNode choose_leaf(const box2 bbox)
            {
                if (is_leaf)
                    return this;

                double best_perimiter = double.max;
                double best_area = double.max;
                RNode best_child = null;
                foreach (RNode child; children)
                {
                    const box2 expanded = child.bounds.expand_to_contain(bbox);
                    const float perimiter = expanded.perimiter;
                    const float area = expanded.area;
                    if (perimiter < best_perimiter || (perimiter == best_perimiter && area < best_area))
                    {
                        best_perimiter = perimiter;
                        best_child = child;
                        best_area = area;
                    }
                }

                return best_child.choose_leaf(bbox);
            }

            private struct SplitResult
            {
                size_t[] items1;
                box2 bbox1;
                size_t[] items2;
                box2 bbox2;
            }

            private void handle_overflow()
            {
                SplitResult t = build_split_linear();

                this.bounds = t.bbox1;
                this.items = t.items1;

                RNode newnode = new RNode(t.bbox2);
                newnode.items = t.items2;

                if (is_root)
                {
                    RNode newroot = new RNode(bounds.expand_to_contain(newnode.bounds));

                    this.parent = newroot;
                    newnode.parent = newroot;
                    newroot.children ~= [this, newnode];
                }
                else
                {
                    newnode.parent = parent;
                    parent.children ~= [newnode];
                }

                this.update_bounds(true);
                newnode.update_bounds(true);

                if (parent.children.length > B)
                {
                    parent.handle_overflow();
                }
            }

            /// Split overflown items into two sets in linear time.
            /// Returns: A SplitResult which can be used to construct new `RNode`.
            private SplitResult build_split_linear() const
            {
                float maxdist = int.min;
                size_t pivot1, pivot2;
                for (int i = 0; i < items.length; i++)
                {
                    const box2 b1 = entities[items[i]].bbox;
                    for (int j = i + 1; j < items.length; j++)
                    {
                        const box2 b2 = entities[items[j]].bbox;

                        const float distx = b1.dist_x(b2);
                        const float disty = b1.dist_y(b2);
                        const float dist = max(distx, disty);

                        if (dist > maxdist)
                        {
                            maxdist = dist;
                            pivot1 = items[i];
                            pivot2 = items[j];
                        }
                    }
                }

                return build_split_from(pivot1, pivot2);
            }

            /// Given the two pivot items, split `items` into two sets to minimize
            /// area expansion of each set.
            /// Params:
            ///   pivot1 = First item.
            ///   pivot2 = Second item.
            /// Returns: A `SplitResult` used in a split method.
            private SplitResult build_split_from(size_t pivot1, size_t pivot2) const
            {
                box2 bbox1 = entities[pivot1].bbox;
                box2 bbox2 = entities[pivot2].bbox;
                size_t[] items1 = [pivot1];
                size_t[] items2 = [pivot2];

                foreach (size_t i; items)
                {
                    if (i == pivot1 || i == pivot2)
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

                return SplitResult(items1, bbox1, items2, bbox2);
            }
        }

        RNode rtree = new RNode(entities[0].bbox);

        foreach (size_t index, Entity e; entities)
        {
            rtree.insert(index);
        }
        rtree = rtree.get_root();
        rtree.draw();

        for (size_t i = 0; i < entities.length; i++)
        {
            Entity e1 = entities[i];
            const box2 bbox1 = e1.bbox;
            foreach (size_t j; rtree.query(bbox1))
            {
                if (i >= j)
                    continue;
                Entity e2 = entities[j];
                if (e1.intersect(e2))
                {
                    result ~= CollisionResult(e1, e2);
                }
            }
        }

        return result;
    }
}

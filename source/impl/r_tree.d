module impl.r_tree;

import collision;
import entity;
import rect;
import std.algorithm.sorting;
import std.array;
import std.typecons;
import vector;
import vendor.sdl;

class RTree
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private int capacity;
    // -------------------------- State
    private RNode root = null;
    // -------------------------- Result
    private CollisionResult[] result;

    this(Entity[] entities, SDL_Renderer* rend, int capacity)
    {
        this.entities = entities;
        this.rend = rend;
        this.capacity = capacity;
    }

    CollisionResult[] get()
    {
        root = null;
        result = [];

        build_tree();
        build_result();
        draw();

        return result;
    }

    private void build_tree()
    {
        root = new RNode(entities, rend, entities[0].bbox, capacity);
        foreach (size_t index, _; entities)
        {
            root.insert(index);
        }
        root = root.get_root();
    }

    private void build_result()
    {
        for (size_t i = 0; i < entities.length; i++)
        {
            Entity e1 = entities[i];
            const box2 bbox1 = e1.bbox;
            foreach (size_t j; root.query(bbox1))
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
    }

    private void draw()
    {
        root.draw();
    }
}

private class RNode
{
    Entity[] entities;
    SDL_Renderer* rend;
    int capacity;

    box2 bounds;
    RNode[] children;
    RNode parent;
    size_t[] items;

    private bool reinserted = false;

    bool is_leaf() const => children.length == 0;
    bool is_root() const => parent is null;

    this(Entity[] entities, SDL_Renderer* rend, box2 bounds, int capacity)
    {
        this.entities = entities;
        this.rend = rend;
        this.bounds = bounds;
        this.capacity = capacity;
    }

    RNode get_root() const
    {
        RNode n = cast(RNode) this;
        while (!n.is_root())
            n = n.parent;
        return n;
    }

    void draw()
    {
        SDL_SetRenderDrawColorFloat(rend, 1, 0, 0, 1);
        SDL_FRect rect = bounds.sdlrect();
        SDL_RenderRect(rend, &rect);
        foreach (RNode child; children)
            child.draw();
    }

    void insert(size_t item)
    {
        const box2 bbox = entities[item].bbox();
        RNode node = choose_leaf(bbox);
        node.items ~= item;

        const bool overflow = node.items.length > capacity;

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
        size_t[] result;
        if (is_leaf && bbox.intersect_inc(bounds))
        {
            foreach (size_t item; items)
            {
                if (entities[item].bbox.intersect_inc(bbox))
                {
                    result ~= item;
                }
            }
        }
        else
        {
            foreach (RNode child; children)
            {
                result ~= child.query(bbox);
            }
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

        float best_perimiter = float.max;
        float best_area = float.max;
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
    /*
    private RNode choose_leaf_star(const box2 bbox)
    {
        if (is_leaf)
            return this;

        float best_overlap = float.max;
        float best_area = float.max;
        float best_perimiter = float.max;
        RNode best_child = null;

        foreach (RNode child; children)
        {
            const box2 expanded = child.bounds.expand_to_contain(bbox);

            const float perimiter = expanded.perimiter - child.bounds.perimiter;
            const float area = expanded.area - child.bounds.area;
            const float overlap = compute_overlap(child, children, bbox);
            if (child.is_leaf)
            {
                if (overlap < best_overlap)
                {
                    best_overlap = overlap;
                    best_perimiter = perimiter;
                    best_area = area;
                    best_child = child;
                }
            }
            else
            {
                if (perimiter < best_perimiter || area < best_area)
                {
                    best_overlap = overlap;
                    best_perimiter = perimiter;
                    best_area = area;
                    best_child = child;
                }
            }
        }

        return best_child.choose_leaf(bbox);
    }
*/
    private float compute_overlap(const RNode child, const RNode[] siblings, box2 bbox) const
    {
        float overlap = 0.0;

        const box2 before = child.bounds;
        const box2 after = child.bounds.expand_to_contain(bbox);

        foreach (const RNode sibling; siblings)
        {
            if (sibling == child)
                continue;
            const box2 o = sibling.bounds;
            overlap += after.intersection(o).area - before.intersection(o).area;
        }

        return overlap;
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

        RNode newnode = new RNode(entities, rend, t.bbox2, capacity);
        newnode.items = t.items2;

        if (is_root)
        {
            RNode newroot = new RNode(entities, rend, bounds.expand_to_contain(newnode.bounds), capacity);

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

        if (parent.children.length > capacity)
        {
            parent.handle_overflow();
        }
    }
    /*
    private void handle_overflow_star()
    {
        if (!reinserted)
        {
            const float percentage = 30.0 / 100.0;
            const int K = cast(int)(percentage * items.length);

            auto t = pick_k_furthest(K);
            const size_t[] to_reinsert = t[0];
            items = t[1];

            reinserted = true;

            RNode root = get_root();
            foreach (size_t item; to_reinsert)
            {
                root.insert(item);
            }

            reinserted = false;
        }

        const bool overflow = items.length > capacity;
        if (overflow)
        {
            handle_overflow();
        }
    }

    private Tuple!(size_t[], size_t[]) pick_k_furthest(int k)
    {
        bool func(size_t i, size_t j)
        {
            vec2 c = bounds.center;
            vec2 dA = c - entities[i].bbox.center;
            vec2 dB = c - entities[j].bbox.center;
            return dA.magnitudeSq > dB.magnitudeSq;
        }

        size_t[] res = sort!(func)(items).array;
        return tuple(res[0 .. k], res[k .. $]);
    }
*/
    /// Split overflown items into two sets in linear time.
    /// Returns: A SplitResult which can be used to construct new `RNode`.
    private SplitResult build_split_linear() const
    {
        float mini = float.infinity;
        float maxi = -float.infinity;
        size_t mini_id = items[0];
        size_t maxi_id = items[1];
        float best_dist = 0;
        size_t[2] best_id = [0, 0];

        for (int d = 0; d < 2; d++)
        {
            foreach (size_t id; items)
            {
                box2 bbox = entities[id].bbox;
                float mini_i = d == 0 ? bbox.left : bbox.top;
                float maxi_i = d == 0 ? bbox.right : bbox.bottom;

                if (mini_i < mini)
                {
                    mini = mini_i;
                    mini_id = id;
                }
                if (maxi_i > maxi)
                {
                    maxi = maxi_i;
                    maxi_id = id;
                }
            }

            float dist = maxi - mini;
            if (dist > best_dist)
            {
                best_dist = dist;
                best_id[0] = mini_id;
                best_id[1] = maxi_id;
            }
        }

        return build_split_from(best_id[0], best_id[1], &cmp_smaller_mbr_enlargement);
    }

    alias SplitRedistMetric = bool delegate(box2, box2, box2);

    private bool cmp_smaller_mbr_enlargement(box2 pivot1, box2 pivot2, box2 obj) const
    {
        box2 exp1 = pivot1.expand_to_contain(obj);
        box2 exp2 = pivot2.expand_to_contain(obj);
        return (exp1.area - pivot1.area) < (exp2.area - pivot2.area);
    }

    /// Given the two pivot items, split `items` based on the comparison function
    /// Params:
    ///   pivot1 = First item.
    ///   pivot2 = Second item.
    ///   cmp = The comparison function.
    /// Returns: A `SplitResult` used in a split method.
    private SplitResult build_split_from(size_t pivot1, size_t pivot2, SplitRedistMetric cmp) const
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

            if (cmp(bbox1, bbox2, b))
            {
                items1 ~= i;
                bbox1 = bbox1.expand_to_contain(b);
            }
            else
            {
                items2 ~= i;
                bbox2 = bbox2.expand_to_contain(b);
            }
        }

        return SplitResult(items1, bbox1, items2, bbox2);
    }
}

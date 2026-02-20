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

    bool is_leaf() const => children.length == 0;
    bool is_root() const => parent is null;

    this(Entity[] entities, SDL_Renderer* rend, box2 bounds, int capacity)
    {
        this.entities = entities;
        this.rend = rend;
        this.bounds = bounds;
        this.capacity = capacity;
    }

    void insert(size_t item)
    {
        const box2 bbox = entities[item].bbox();
        RNode node = choose_leaf(bbox);
        node.items ~= item;

        if (node.items.length > capacity)
            node.handle_overflow();
        else
            node.update_bounds(true);
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

    size_t[] query(const box2 bbox)
    {
        size_t[] result;
        if (is_leaf && bbox.intersect_inc(bounds))
        {
            foreach (size_t item; items)
                if (entities[item].bbox.intersect_inc(bbox))
                    result ~= item;
        }
        else
        {
            foreach (RNode child; children)
                result ~= child.query(bbox);
        }
        return result;
    }

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

    private RNode choose_leaf(const box2 bbox)
    {
        if (is_leaf)
            return this;

        float best_perimeter = float.max;
        float best_area = float.max;
        RNode best_child = null;

        foreach (RNode child; children)
        {
            const box2 expanded = child.bounds.expand_to_contain(bbox);
            const float perimeter = expanded.perimiter;
            const float area = expanded.area;
            if (perimeter < best_perimeter || (perimeter == best_perimeter && area < best_area))
            {
                best_perimeter = perimeter;
                best_area = area;
                best_child = child;
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
        RNode[] children1;
        RNode[] children2;
    }

    alias SplitRedistMetric = bool delegate(box2, box2, box2);

    private void handle_overflow()
    {
        SplitResult t = build_split_linear();

        if (is_leaf)
        {
            this.items = t.items1;
            this.bounds = t.bbox1;

            RNode newnode = new RNode(entities, rend, t.bbox2, capacity);
            newnode.items = t.items2;
            attach_split(newnode);
        }
        else
        {
            this.children = t.children1;
            this.bounds = t.bbox1;

            RNode newnode = new RNode(entities, rend, t.bbox2, capacity);
            newnode.children = t.children2;
            foreach (RNode c; newnode.children)
                c.parent = newnode;
            attach_split(newnode);
        }

        this.update_bounds(true);
    }

    private void attach_split(RNode newnode)
    {
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
            if (parent.children.length > capacity)
                parent.handle_overflow();
        }
    }

    private SplitResult build_split_linear()
    {
        if (is_leaf)
        {
            size_t[2] seeds = pick_seeds_items();
            return build_split_from_items(seeds[0], seeds[1], &cmp_smaller_mbr_enlargement);
        }
        else
        {
            RNode[2] seeds = pick_seeds_children();
            return build_split_from_children(seeds[0], seeds[1], &cmp_smaller_mbr_enlargement);
        }
    }

    private size_t[2] pick_seeds_items()
    {
        float best_dist = -float.infinity;
        size_t[2] best_id;
        for (int d = 0; d < 2; d++)
        {
            float mini = float.infinity, maxi = -float.infinity;
            size_t mini_id, maxi_id;
            foreach (size_t id; items)
            {
                box2 bbox = entities[id].bbox;
                float val_min = d == 0 ? bbox.left : bbox.top;
                float val_max = d == 0 ? bbox.right : bbox.bottom;
                if (val_min < mini)
                {
                    mini = val_min;
                    mini_id = id;
                }
                if (val_max > maxi)
                {
                    maxi = val_max;
                    maxi_id = id;
                }
            }
            float dist = maxi - mini;
            if (dist > best_dist)
            {
                best_dist = dist;
                best_id = [mini_id, maxi_id];
            }
        }
        return best_id;
    }

    private RNode[2] pick_seeds_children()
    {
        float best_dist = -float.infinity;
        RNode[2] best_child;
        for (int d = 0; d < 2; d++)
        {
            float mini = float.infinity, maxi = -float.infinity;
            RNode mini_child, maxi_child;
            foreach (RNode child; children)
            {
                box2 bbox = child.bounds;
                float val_min = d == 0 ? bbox.left : bbox.top;
                float val_max = d == 0 ? bbox.right : bbox.bottom;
                if (val_min < mini)
                {
                    mini = val_min;
                    mini_child = child;
                }
                if (val_max > maxi)
                {
                    maxi = val_max;
                    maxi_child = child;
                }
            }
            float dist = maxi - mini;
            if (dist > best_dist)
            {
                best_dist = dist;
                best_child = [mini_child, maxi_child];
            }
        }
        return best_child;
    }

    private bool cmp_smaller_mbr_enlargement(box2 pivot1, box2 pivot2, box2 obj) const
    {
        box2 exp1 = pivot1.expand_to_contain(obj);
        box2 exp2 = pivot2.expand_to_contain(obj);
        return (exp1.area - pivot1.area) < (exp2.area - pivot2.area);
    }

    private SplitResult build_split_from_items(size_t pivot1, size_t pivot2, SplitRedistMetric cmp)
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
        return SplitResult(items1, bbox1, items2, bbox2, null, null);
    }

    private SplitResult build_split_from_children(RNode pivot1, RNode pivot2, SplitRedistMetric cmp)
    {
        box2 bbox1 = pivot1.bounds;
        box2 bbox2 = pivot2.bounds;
        RNode[] children1 = [pivot1];
        RNode[] children2 = [pivot2];

        foreach (RNode c; children)
        {
            if (c == pivot1 || c == pivot2)
                continue;
            box2 b = c.bounds;
            if (cmp(bbox1, bbox2, b))
            {
                children1 ~= c;
                bbox1 = bbox1.expand_to_contain(b);
            }
            else
            {
                children2 ~= c;
                bbox2 = bbox2.expand_to_contain(b);
            }
        }
        return SplitResult(null, bbox1, null, bbox2, children1, children2);
    }
}

module impl.bulk_r_tree;

import collision;
import entity;
import rect;
import std.algorithm;
import std.algorithm.iteration;
import std.algorithm.sorting;
import std.array;
import std.math;
import std.typecons;
import vector;
import vendor.sdl;

class BulkRTree
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private int capacity;
    private Type type;
    // -------------------------- State
    private BulkRNode root = null;
    int hilbert_bits = 16;
    // -------------------------- Result
    private CollisionResult[] result;

    enum Type
    {
        SortX,
        SortTileRecursive,
        Hilbert,
    }

    this(Entity[] entities, SDL_Renderer* rend, int capacity, Type type)
    {
        this.entities = entities;
        this.rend = rend;
        this.capacity = capacity;
        this.type = type;
    }

    CollisionResult[] get()
    {
        root = null;
        result = [];

        size_t[] indexlist;
        for (size_t i = 0; i < entities.length; i++)
            indexlist ~= i;

        final switch (type) with (Type)
        {
        case SortX:
            build_nearest_x(indexlist);
            break;
        case SortTileRecursive:
            build_str(indexlist);
            break;
        case Hilbert:
            build_hilbert(indexlist);
            break;
        }

        build_result();
        draw();

        return result;
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

    private void build_nearest_x(size_t[] list)
    {
        bool cmp_x(size_t i, size_t j) => entities[i].bbox.center.x < entities[j].bbox.center.x;
        list = sort!(cmp_x)(list).array();

        BulkRNode[] level;
        int cap = capacity;

        // Leaf layer
        for (int i = 0; i < list.length; i += cap)
        {
            const size_t l = i;
            const size_t r = min(list.length, l + cap);

            BulkRNode n = new BulkRNode(entities, rend);
            n.items = list[i .. r];
            n.update_bounds();
            level ~= n;
        }

        // Internal layer
        while (level.length > 1)
        {
            cap = cast(int) ceil(cast(double) level.length / cast(double) cap);
            if (cap == 1)
                cap = 2;

            BulkRNode[] newlevel = [];

            for (int i = 0; i < level.length; i += cap)
            {
                const size_t l = i;
                const size_t r = min(level.length, l + cap);

                BulkRNode n = new BulkRNode(entities, rend);
                for (size_t j = l; j < r; j++)
                {
                    n.children ~= level[j];
                    level[j].parent = n;
                }
                n.update_bounds();

                newlevel ~= n;
            }

            level = newlevel;
        }

        root = level[0];
    }

    private void build_str(size_t[] list)
    {
        bool cx(size_t i, size_t j) => entities[i].bbox.center.x < entities[j].bbox.center.x;
        bool cy(size_t i, size_t j) => entities[i].bbox.center.y < entities[j].bbox.center.y;
        list = sort!(cx)(list).array();

        {
            const int slice_size = cast(int) ceil(sqrt(cast(double) list.length / capacity));
            size_t[] list_sorty;
            for (int i = 0; i < list.length; i += slice_size)
            {
                int l = i;
                int r = min(i + slice_size, list.length);

                size_t[] slice = list[l .. r];
                slice = sort!(cy)(slice).array();
                list_sorty ~= slice;
            }
            list = list_sorty;
        }

        BulkRNode[] level;
        for (int i = 0; i < list.length; i += capacity)
        {
            int l = i;
            int r = min(i + capacity, list.length);

            BulkRNode n = new BulkRNode(entities, rend);
            n.items = list[l .. r];
            n.update_bounds();

            level ~= n;
        }

        while (level.length > 1)
        {
            // Sort by x [not needed, centroids of disjoint groups of N sorted points are sorted themselves]

            // Slice and sort by y
            {
                const int slice_size = cast(int) ceil(sqrt(cast(double) level.length / capacity));
                BulkRNode[] level_sorty;
                for (int i = 0; i < level.length; i += slice_size)
                {
                    int l = i;
                    int r = min(i + slice_size, level.length);

                    BulkRNode[] slice = level[l .. r];
                    slice = sort!"a.bounds.center.y < b.bounds.center.y"(slice).array();
                    level_sorty ~= slice;
                }
                level = level_sorty;
            }

            // Build next level
            {
                BulkRNode[] newlevel;
                for (int i = 0; i < level.length; i += capacity)
                {
                    int l = i;
                    int r = min(i + capacity, level.length);

                    BulkRNode n = new BulkRNode(entities, rend);
                    for (int j = l; j < r; j++)
                    {
                        n.children ~= level[j];
                        level[j].parent = n;
                    }
                    n.update_bounds();

                    newlevel ~= n;
                }
                level = newlevel;
            }
        }

        root = level[0];
    }

    private void build_hilbert(size_t[] list)
    {
        int n_bits = hilbert_bits;
        bool cmp(size_t i, size_t j)
        {
            ulong h_i = hilbert_value(entities[i].bbox.center, n_bits);
            ulong h_j = hilbert_value(entities[j].bbox.center, n_bits);
            return h_i < h_j;
        }

        list = sort!(cmp)(list).array();

        BulkRNode[] level;
        int cap = capacity;

        // Leaf layer
        for (int i = 0; i < list.length; i += cap)
        {
            const size_t l = i;
            const size_t r = min(list.length, l + cap);

            BulkRNode n = new BulkRNode(entities, rend);
            n.items = list[i .. r];
            n.update_bounds();
            level ~= n;
        }

        // Internal layer
        while (level.length > 1)
        {
            cap = cast(int) ceil(cast(double) level.length / cast(double) cap);
            if (cap == 1)
                cap = 2;

            BulkRNode[] newlevel = [];

            for (int i = 0; i < level.length; i += cap)
            {
                const size_t l = i;
                const size_t r = min(level.length, l + cap);

                BulkRNode n = new BulkRNode(entities, rend);
                for (size_t j = l; j < r; j++)
                {
                    n.children ~= level[j];
                    level[j].parent = n;
                }
                n.update_bounds();

                newlevel ~= n;
            }

            level = newlevel;
        }

        root = level[0];
    }

    private ulong hilbert_value(vec2 p, int n_bits)
    {
        ulong mask = 1 << (n_bits - 1);

        ulong x = cast(ulong) p.x;
        ulong y = cast(ulong) p.y;

        ulong index = 0;

        for (int i = 0; i < n_bits; i++)
        {
            ulong rx = (x & mask) > 0;
            ulong ry = (y & mask) > 0;
            ulong quad = (rx << 1) ^ ry;
            index = (index << 2) | quad;

            if (ry == 0)
            {
                if (rx == 1)
                {
                    x = (1 << n_bits) - (1 + x);
                    y = (1 << n_bits) - (1 + y);
                }
                swap(x, y);
            }
            mask >>= 1;
        }

        return index;
    }

}

class BulkRNode
{
    Entity[] entities;
    SDL_Renderer* rend;

    box2 bounds;
    BulkRNode[] children;
    BulkRNode parent;
    size_t[] items;

    this(Entity[] entities, SDL_Renderer* rend)
    {
        this.entities = entities;
        this.rend = rend;
    }

    bool is_leaf() const => children.length == 0;
    bool is_root() const => parent is null;

    /// Update bounding boxes of this node and parent nodes recurively.
    private void update_bounds()
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
            foreach (BulkRNode child; children[1 .. $])
                bounds = bounds.expand_to_contain(child.bounds);
        }
        if (!is_root)
            parent.update_bounds();
    }

    private void draw()
    {
        SDL_SetRenderDrawColorFloat(rend, 1, 0, 0, 1.0);
        SDL_FRect rect = bounds.sdlrect();
        SDL_RenderRect(rend, &rect);
        foreach (BulkRNode child; children)
            child.draw();
    }

    /// Find all items which are candidates for intersection with `bbox`.
    private size_t[] query(const box2 bbox)
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
            foreach (BulkRNode child; children)
            {
                result ~= child.query(bbox);
            }
        }
        return result;
    }
}

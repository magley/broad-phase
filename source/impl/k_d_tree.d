module impl.k_d_tree;

import collision;
import entity;
import rect;
import std.algorithm;
import std.algorithm.sorting;
import std.array;
import std.typecons;
import vector;
import vendor.sdl;

class KDTree
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private int capacity;
    // -------------------------- State
    private KDNode root = null;
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
        size_t[] items;
        foreach (size_t item, _; entities)
            items ~= item;
        root = new KDNode(entities, rend, capacity, 0, items);
    }

    private void build_result()
    {
        for (size_t i = 0; i < entities.length; i++)
        {
            Entity e1 = entities[i];
            const box2 bbox1 = e1.bbox;
            foreach (size_t j; root.query(i, bbox1))
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

class KDNode
{
    const int DIM = 2;

    Entity[] entities;
    SDL_Renderer* rend;
    int capacity;

    int axis;
    float median;
    KDNode[] children;
    size_t[] items;

    bool is_leaf()
    {
        return children.length == 0;
    }

    this(Entity[] entities, SDL_Renderer* rend, int capacity, int axis, size_t[] items)
    {
        this.entities = entities;
        this.rend = rend;
        this.axis = axis;
        this.capacity = max(capacity, 1 << DIM);
        insert(items);
    }

    void draw()
    {

    }

    private void insert(size_t[] items)
    {
        if (items.length <= capacity)
        {
            this.items = items;
        }
        else
        {
            bool less(size_t i, size_t j) const
            {
                box2 bbox1 = entities[i].bbox;
                box2 bbox2 = entities[j].bbox;
                if (axis == 0)
                    return bbox1.right < bbox2.right;
                return bbox1.bottom < bbox2.bottom;
            }

            float value(size_t i) const
            {
                box2 bbox = entities[i].bbox;
                if (axis == 0)
                    return bbox.right;
                return bbox.bottom;
            }

            size_t[] sorted = sort!less(items).array();
            size_t M = sorted.length / 2;
            this.median = value(sorted[M]);

            int ax = (axis + 1) % DIM;
            this.children ~= new KDNode(entities, rend, capacity, ax, sorted[0 .. M + 1]);
            this.children ~= new KDNode(entities, rend, capacity, ax, sorted[M + 1 .. $]);
        }
    }

    size_t[] query(size_t item, const box2 bbox)
    {
        size_t[] result;
        if (is_leaf)
        {
            foreach (size_t i; items)
            {
                if (i == item)
                    continue;
                if (bbox.intersect(entities[i].bbox))
                {
                    result ~= i;
                }
            }
        }
        else
        {
            bool traverse_left = true;
            bool traverse_right = true;
            if (axis == 0)
            {
                if (bbox.left > median)
                    traverse_left = false;
            }
            else
            {
                if (bbox.top > median)
                    traverse_left = false;

            }

            if (traverse_left)
                result ~= children[0].query(item, bbox);
            if (traverse_right)
                result ~= children[1].query(item, bbox);
        }
        return result;
    }
}

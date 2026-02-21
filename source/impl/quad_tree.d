module impl.quad_tree;

import collision;
import entity;
import impl;
import rect;
import std.typecons;
import vector;
import vendor.sdl;

class QuadTree : IBroadPhaseImplementation
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private box2 space;
    private int capacity;
    // -------------------------- State
    private QuadNode root = null;
    // -------------------------- Result
    private CollisionResult[] result;

    this(Entity[] entities, SDL_Renderer* rend, box2 space, int capacity)
    {
        this.entities = entities;
        this.rend = rend;
        this.space = space;
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
        root = new QuadNode(entities, rend, space, capacity);
        foreach (size_t i, Entity e; entities)
        {
            root.insert(i);
        }
    }

    private void build_result()
    {
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

    }

    private void draw()
    {
        root.draw();
    }
}

private class QuadNode
{
    private Entity[] entities;
    private SDL_Renderer* rend;

    QuadNode[4] child;
    box2 area;
    int capacity;

    size_t[] items;

    this(Entity[] entities, SDL_Renderer* rend, box2 area, int capacity)
    {
        this.entities = entities;
        this.rend = rend;
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

        if (child[0] is null)
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
        child[0] = new QuadNode(entities, rend, box2.pos_sz(area.ul + area.size * vec2(0, 0) / 2, area.size / 2), capacity);
        child[1] = new QuadNode(entities, rend, box2.pos_sz(area.ul + area.size * vec2(1, 0) / 2, area.size / 2), capacity);
        child[2] = new QuadNode(entities, rend, box2.pos_sz(area.ul + area.size * vec2(0, 1) / 2, area.size / 2), capacity);
        child[3] = new QuadNode(entities, rend, box2.pos_sz(area.ul + area.size * vec2(1, 1) / 2, area.size / 2), capacity);
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

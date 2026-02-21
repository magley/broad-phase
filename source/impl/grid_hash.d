module impl.grid_hash;

import collision;
import entity;
import impl;
import rect;
import std.typecons;
import vector;
import vendor.sdl;

class GridHash : IBroadPhaseImplementation
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private vec2 cell;
    // -------------------------- State
    private Entity[][ulong] buckets;
    // -------------------------- Result
    private CollisionResult[] result;
    private PerfMeasure perf_measure;
    PerfMeasure get_performance() => perf_measure;

    this(Entity[] entities, SDL_Renderer* rend, vec2 cell_size)
    {
        this.entities = entities;
        this.rend = rend;
        this.cell = cell_size;
        this.perf_measure = new PerfMeasure();
    }

    CollisionResult[] get()
    {
        buckets = null;
        result = [];

        perf_measure.start("build_space");
        build_buckets();
        perf_measure.start("build_result");
        build_result();
        perf_measure.start("draw");
        draw();
        perf_measure.end();

        return result;
    }

    private ulong hash(vec2 point, vec2 cell)
    {
        return (point / cell).floor().toHash();
    }

    private void build_buckets()
    {
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
    }

    private void build_result()
    {
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
    }

    private void draw()
    {
        SDL_SetRenderDrawColorFloat(rend, 1, 0, 0, 1);
        for (float x = 0 - cell.x; x <= 800 + cell.x; x += cell.x)
        {
            SDL_RenderLine(rend, x, -100, x, 600 + 100);
        }
        for (float y = 0 - cell.y; y <= 600 + cell.y; y += cell.y)
        {
            SDL_RenderLine(rend, -100, y, 800 + 100, y);
        }
    }
}

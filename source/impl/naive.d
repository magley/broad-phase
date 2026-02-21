module impl.naive;

import collision;
import entity;
import impl;
import rect;
import std.algorithm.sorting;
import std.array;
import std.typecons;
import vector;
import vendor.sdl;

class Naive : IBroadPhaseImplementation
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    // -------------------------- Result
    private CollisionResult[] result;
    private PerfMeasure perf_measure;
    PerfMeasure get_performance() => perf_measure;

    this(Entity[] entities, SDL_Renderer* rend)
    {
        this.entities = entities;
        this.rend = rend;
        this.perf_measure = new PerfMeasure();
    }

    CollisionResult[] get()
    {
        result = [];
        perf_measure.start("build_result");
        build_result();
        perf_measure.end();
        return result;
    }

    private void build_result()
    {
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
    }
}

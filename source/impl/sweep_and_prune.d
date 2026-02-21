module impl.sweep_and_prune;

import collision;
import entity;
import impl;
import rect;
import std.algorithm.sorting;
import std.array;
import std.typecons;
import vector;
import vendor.sdl;

class SweepAndPrune : IBroadPhaseImplementation
{
    // -------------------------- Input 
    private Entity[] entities;
    private SDL_Renderer* rend;
    private vec2 cell;
    // -------------------------- State
    private SweepPoint[] points;
    // -------------------------- Result
    private CollisionResult[] result;

    this(Entity[] entities, SDL_Renderer* rend)
    {
        this.entities = entities;
        this.rend = rend;
    }

    CollisionResult[] get()
    {
        result = [];
        points = [];

        build_sorted_points();
        sweep_and_prune();

        return result;
    }

    private void build_sorted_points()
    {
        reserve(points, entities.length * 2);

        foreach (size_t i, Entity e; entities)
        {
            points ~= SweepPoint(e.bbox.left, i, true);
            points ~= SweepPoint(e.bbox.right, i, false);
        }
        points = sort!"a.val < b.val"(points).array();
    }

    private void sweep_and_prune()
    {
        bool[size_t] set;

        foreach (ref SweepPoint p; points)
        {
            if (p.isMini)
            {
                foreach (size_t eIndex, _; set)
                {
                    Entity e1 = entities[p.index];
                    Entity e2 = entities[eIndex];

                    if (e1.intersect(e2))
                    {
                        result ~= CollisionResult(e1, e2);
                    }
                }

                set[p.index] = true;
            }
            else
            {
                set.remove(p.index);
            }
        }
    }
}

private struct SweepPoint
{
    float val;
    size_t index;
    bool isMini;
}

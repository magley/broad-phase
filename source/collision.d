module collision;

import core.stdc.limits;
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
        BulkRTree_X,
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
        case BulkRTree_X:
            return update_bulk_r_tree_x(e, rend);
        }
    }

    private CollisionResult[] update_none(Entity[] entities, SDL_Renderer* rend)
    {
        return [];
    }

    private CollisionResult[] update_naive(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.naive;

        Naive gh = new Naive(entities, rend);
        return gh.get();
    }

    private CollisionResult[] update_grid_hash(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.grid_hash;

        GridHash gh = new GridHash(entities, rend, vec2(50, 50));
        return gh.get();
    }

    private CollisionResult[] update_sort_and_sweep(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.sweep_and_prune;

        SweepAndPrune sp = new SweepAndPrune(entities, rend);
        return sp.get();
    }

    private CollisionResult[] update_quad_tree(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.quad_tree;

        QuadTree qt = new QuadTree(entities, rend, box2.pos_sz(vec2(), vec2(800, 600)), 5);
        return qt.get();
    }

    private CollisionResult[] update_r_tree(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.r_tree;

        RTree rt = new RTree(entities, rend, 100);
        return rt.get();
    }

    private CollisionResult[] update_bulk_r_tree_x(Entity[] entities, SDL_Renderer* rend)
    {
        import impl.bulk_r_tree;

        BulkRTree rt = new BulkRTree(entities, rend, 100);
        return rt.get();
    }

}

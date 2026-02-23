module collision;

import core.stdc.limits;
import entity;
import impl;
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

    void draw(SDL_Renderer* rend)
    {
        float r = e1.bbox.left / 800.0f;
        float g = e2.bbox.top / 600.0f;
        float b = (e1.bbox.w + e2.bbox.h) / 64.0f;

        SDL_SetRenderDrawColorFloat(rend, r, g, b, 0.1);

        SDL_FRect rect;
        rect.x = e1.bbox.x;
        rect.y = e1.bbox.y;
        rect.w = e1.bbox.w;
        rect.h = e1.bbox.h;
        SDL_RenderFillRect(rend, &rect);
        SDL_FRect rect2;
        rect2.x = e2.bbox.x;
        rect2.y = e2.bbox.y;
        rect2.w = e2.bbox.w;
        rect2.h = e2.bbox.h;
        SDL_RenderFillRect(rend, &rect2);
    }
}

class Collision
{
    IBroadPhaseImplementation[string] strategies;
    string[] strategy_names = [];
    int strategy_index = 0;
    string strategy() => strategy_names[strategy_index];

    Entity[] entities;
    SDL_Renderer* rend;
    Input* input;

    CollisionResult[] result;

    this(Input* input, SDL_Renderer* rend)
    {
        this.input = input;
        this.rend = rend;
    }

    void initialize(Entity[] entities)
    {
        this.entities = entities;
        strategies["00 None"] = new NoneImpl();
        strategies["01 Naive"] = new Naive(entities, rend);
        strategies["02 Grid Hash"] = new GridHash(entities, rend, vec2(50, 50));
        strategies["03 Sweep and Prune"] = new SweepAndPrune(entities, rend);
        strategies["04 Quad tree"] = new QuadTree(entities, rend, box2.pos_sz(vec2(), vec2(800, 600)), 5);
        strategies["05 R tree"] = new RTree(entities, rend, 100);
        strategies["06 R tree (X-sort)"] = new BulkRTree(entities, rend, 8, BulkRTree.Type.SortX);
        strategies["07 R tree (STR)"] = new BulkRTree(entities, rend, 8, BulkRTree
                .Type.SortTileRecursive);
        strategies["08 R tree (Hilbert)"] = new BulkRTree(entities, rend, 8, BulkRTree.Type.Hilbert);
        strategies["09 K-d tree"] = new KDTree(entities, rend, 64);

        strategy_names = strategies.keys;
        sort(strategy_names);
    }

    void move(int delta_strategy)
    {
        strategy_index += delta_strategy;
        if (strategy_index >= strategy_names.length)
        {
            strategy_index = 0;
        }
        if (strategy_index < 0)
        {
            strategy_index = cast(int) strategy_names.length - 1;
        }
    }

    void update()
    {
        result = [];

        if (strategy !in strategies)
        {
            writeln("Unknown strategy " ~ strategy);
            return;
        }

        result = strategies[strategy].get();
    }

    PerfMeasure get_performance_measure()
    {
        if (strategy !in strategies)
        {
            writeln("Unknown strategy " ~ strategy);
            return null;
        }

        return strategies[strategy].get_performance();
    }
}

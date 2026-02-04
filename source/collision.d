module collision;

import entity;
import rect;
import std.algorithm;
import std.algorithm.sorting;
import std.array;
import std.datetime.stopwatch;
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
    }

    Type type = Type.None;

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
        }
    }

    private CollisionResult[] update_none(Entity[] entities, SDL_Renderer* rend)
    {
        return [];
    }

    private CollisionResult[] update_naive(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;

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

        return result;
    }

    private CollisionResult[] update_grid_hash(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;
        const vec2 cell = vec2(50, 50);

        ulong hash(vec2 point, vec2 cell) => (point / cell).floor().toHash();

        // Build buckets
        Entity[][ulong] buckets;
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

        // Collision within buckets

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

        // Draw grid
        SDL_SetRenderDrawColorFloat(rend, 1, 1, 0, 1);
        for (float x = 0 - cell.x; x <= 800 + cell.x; x += cell.x)
        {
            SDL_RenderLine(rend, x, -100, x, 600 + 100);
        }
        for (float y = 0 - cell.y; y <= 600 + cell.y; y += cell.y)
        {
            SDL_RenderLine(rend, -100, y, 800 + 100, y);
        }

        return result;
    }

    private CollisionResult[] update_sort_and_sweep(Entity[] entities, SDL_Renderer* rend)
    {
        CollisionResult[] result;

        struct SweepPoint
        {
            float val;
            size_t index;
            bool isMini;
        }

        SweepPoint[] points;

        // Sort

        reserve(points, entities.length * 2);
        foreach (size_t i, Entity e; entities)
        {
            points ~= SweepPoint(e.bbox.left, i, true);
            points ~= SweepPoint(e.bbox.right, i, false);
        }
        points = sort!"a.val < b.val"(points).array();

        // Sweep

        size_t[] set;
        foreach (ref SweepPoint p; points)
        {
            if (p.isMini)
            {
                foreach (size_t eIndex; set)
                {
                    Entity e1 = entities[p.index];
                    Entity e2 = entities[eIndex];

                    if (e1.intersect(e2))
                    {
                        result ~= CollisionResult(e1, e2);
                    }
                }

                set ~= p.index;
            }
            else
            {
                int i = 0;
                for (int j = 0; j < set.length; j++)
                {
                    if (set[j] == p.index)
                    {
                        i = j;
                        break;
                    }
                }
                set = set[0 .. i] ~ set[i + 1 .. $];
            }
        }

        return result;
    }
}

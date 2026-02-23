module benchmark.placement;
import benchmark;

import entity;
import std.math;
import std.random;
import vector;

enum Placement
{
    Random,
    RandomLargeBoxes,
    XLine,
    YLine,
    TrueUniform
}

package Entity[] spawn_entities(int count, Placement placement, int iter)
{
    Entity[] entities;
    const int N = count;

    entities.reserve(N);

    Random rnd = Random(0 + N + iter);

    final switch (placement) with (Placement)
    {
    case Random:
        for (int i = 0; i < N; i++)
        {
            entities ~= new Entity(
                vec2(uniform!"[]"(0, 800 - 16, rnd), uniform!"[]"(0, 600 - 16, rnd)),
                vec2(uniform!"[]"(12, 16, rnd), uniform!"[]"(12, 16, rnd)),
            );
        }
        break;
    case RandomLargeBoxes:
        for (int i = 0; i < N; i++)
        {
            entities ~= new Entity(
                vec2(uniform!"[]"(0, 800 - 100, rnd), uniform!"[]"(0, 600 - 100, rnd)),
                vec2(uniform!"[]"(50, 100, rnd), uniform!"[]"(50, 100, rnd)),
            );
        }
        break;
    case XLine:
        int x = 800 / 2 - 300 / 2;
        for (int i = 0; i < N; i++)
        {
            float p = cast(float) i / N;
            entities ~= new Entity(
                vec2(x, p * ((600 - 20) - 0) + 0),
                vec2(uniform!"[]"(30, 300, rnd), uniform!"[]"(10, 20, rnd)),
            );
        }
        break;
    case YLine:
        int y = 600 / 2 - 300 / 2;
        for (int i = 0; i < N; i++)
        {
            float p = cast(float) i / N;
            entities ~= new Entity(
                vec2(p * ((800 - 20) - 0) + 0, y),
                vec2(uniform!"[]"(10, 20, rnd), uniform!"[]"(30, 300, rnd)),
            );
        }
        break;
    case TrueUniform:
        const float Nf = cast(float) N;
        const int nRow = cast(int)(sqrt(Nf) + sqrt(sqrt(Nf)) * iter);
        const int nPerRow = N / nRow;
        const int w = 800 / nPerRow;
        const int h = 600 / nRow;
        const vec2 entitySize = vec2(w, h) + vec2(1, 1) * 10;
        for (int y = 0; y < nRow; y++)
        {
            for (int x = 0; x < nPerRow; x++)
            {
                entities ~= new Entity(vec2(x * w, y * h), entitySize);
            }
        }
    }

    return entities;
}

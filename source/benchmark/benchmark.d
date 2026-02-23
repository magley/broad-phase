module benchmark.benchmark;
import benchmark;

import impl;
import std.array;
import std.format;
import std.json;

class BenchmarkResults
{
    string[] lines;

    void placement(Placement p)
    {
        lines ~= format("P %s", p);
    }

    void entityCount(int N)
    {
        lines ~= format("N %d", N);
    }

    void run(string strategy, PerfMeasure run)
    {
        string s = format("r %s ", strategy.replace(' ', '_'));
        foreach (string key, size_t val; run.data)
        {
            s ~= format("%s:%d ", key, val);
        }
        lines ~= s;
    }
}

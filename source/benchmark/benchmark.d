module benchmark.benchmark;
import benchmark;

import impl;
import std.json;

class Benchmark
{
    PerfMeasure[][string] measures;

    void push(string strategy, PerfMeasure measure)
    {
        measures[strategy] ~= measure;
    }

    string to_json()
    {
        JSONValue j;

        foreach (string strategy, _; measures)
        {
            j[strategy] = JSONValue.emptyArray;
        }

        foreach (string strategy, PerfMeasure[] mli; measures)
        {
            JSONValue[] li;
            foreach (PerfMeasure frame; mli)
            {
                JSONValue obj;
                foreach (string task, ulong time; frame.data)
                {
                    obj[task] = time;
                }
                li ~= obj;
            }
            j[strategy] ~= li;
        }

        return j.toString();
    }
}

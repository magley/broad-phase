module impl;

import collision;
import std.datetime.stopwatch;

public import impl.bulk_r_tree;
public import impl.grid_hash;
public import impl.k_d_tree;
public import impl.naive;
public import impl.none;
public import impl.quad_tree;
public import impl.r_tree;
public import impl.sweep_and_prune;

class PerfMeasure
{
    size_t[string] data;
    private string current = "";
    private StopWatch sw;

    void start(string name)
    {
        if (current != "")
        {
            end();
        }
        sw.reset();
        current = name;
        data[name] = 0;
        sw.start();
    }

    void end()
    {
        sw.stop();
        data[current] = sw.peek().total!"msecs"();
        current = "";
    }
}

interface IBroadPhaseImplementation
{
    CollisionResult[] get();
    PerfMeasure get_performance();
}

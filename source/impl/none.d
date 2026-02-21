module impl.none;
import collision;
import impl;

class NoneImpl : IBroadPhaseImplementation
{
    PerfMeasure perf_measure;
    PerfMeasure get_performance() => perf_measure;

    this()
    {
        perf_measure = new PerfMeasure();
    }

    CollisionResult[] get()
    {
        return [];
    }
}

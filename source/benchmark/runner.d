module benchmark.runner;
import benchmark;
import collision;
import entity;
import impl;
import std.datetime.stopwatch;
import std.format;
import std.string;
import std.traits;

struct SingleRunInputState
{
    int entityCount;
    Placement placement;
    size_t strategyIndex;
}

void begin_benchmarking(BenchmarkState state)
{
    Placement[] placements = [EnumMembers!(Placement)];
    int[] entityCounts = [10, 100, 500, 1000, 2000];
    size_t[] strategies;
    for (size_t i = 0; i < state.cld.strategies.length; i++)
        strategies ~= i;

    state.progress = 0;
    state.progressMax = placements.length * entityCounts.length * strategies.length * state.nIter;

    foreach (Placement placement; placements)
    {
        state.benchmark.placement(placement);
        foreach (int entityCount; entityCounts)
        {
            state.benchmark.entityCount(entityCount);

            state.cached_entities = [];
            for (int i = 0; i < state.nIter; i++)
            {
                state.cached_entities ~= spawn_entities(entityCount, placement, i);
            }

            foreach (size_t strategy; strategies)
            {
                SingleRunInputState input = SingleRunInputState(entityCount, placement, strategy);
                PerfMeasure[] result = single_run(state, input);

                foreach (ref PerfMeasure p; result)
                {
                    state.benchmark.run(state.cld.strategy_names[strategy], p);
                }
            }
        }
    }
}

private PerfMeasure[] single_run(BenchmarkState state, SingleRunInputState input_)
{
    // TODO: Headless mode.

    import vendor.sdl;

    // Refs
    Collision cld = state.cld;
    const int nIter = cast(int) state.nIter;
    Entity[][] cached_entities = state.cached_entities;
    SDL_Renderer* rend = state.rend;
    BenchmarkResults benchmark = state.benchmark;
    //

    PerfMeasure[] result;

    StopWatch sw;
    sw.start();

    cld.strategy_index = cast(int) input_.strategyIndex;
    for (int iter = 0; iter < nIter; iter++)
    {
        Entity[] entities = cached_entities[iter];
        cld.initialize(entities);

        if (!state.headless)
        {
            SDL_Event ev;
            while (SDL_PollEvent(&ev))
            {
                if (ev.type == SDL_EVENT_QUIT)
                {
                    throw new Exception("Program interrupted by user.");
                }
                else if (ev.type == SDL_EVENT_MOUSE_WHEEL)
                {
                    state.input.wheel = ev.wheel.y;
                }
            }
            SDL_SetRenderDrawColorFloat(rend, 1, 1, 1, 1.0);
            SDL_RenderClear(rend);

            foreach (Entity e; entities)
            {
                e.draw(rend);
            }
        }

        sw.reset();

        // ------------------------------------------------

        cld.update();
        CollisionResult[] cld_result = cld.result;
        result ~= cld.get_performance_measure();

        // ------------------------------------------------
        long exec_ms = sw.peek().total!"msecs"();

        if (!state.headless)
        {
            foreach (ref CollisionResult res; cld_result)
                res.draw(rend);

            SDL_RenderPresent(rend);
        }

        // ------------------------------------------------

        state.progress++;

        if (!state.headless)
        {
            long fps = cast(long)(1000.0 / exec_ms);
            SDL_SetWindowTitle(state.win,
                format("[%d/%d] [%d/%d] T: %s, P: %s,  N: %d, C: %d,  fps: %03d, latency: %dms",
                    state.progress + 1, state.progressMax,
                    iter + 1, nIter,
                    input_.placement,
                    cld.strategy(),
                    entities.length,
                    cld_result.length,
                    fps,
                    exec_ms
            ).toStringz
            );
        }
    }

    return result;
}

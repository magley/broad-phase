module benchmark;

public import benchmark.benchmark;
public import benchmark.placement;
public import benchmark.runner;
public import benchmark.state;

import collision;
import vendor.sdl;

void start_benchmark(bool headless)
{
    BenchmarkState state = new BenchmarkState(headless);
    system_init(state);
    {
        begin_benchmarking(state);

        {
            import std.array;
            import std.file;

            write("./benchmark/result.txt", state.benchmark.lines.join("\n"));
        }
    }
    system_fini(state);
}

private void system_init(BenchmarkState state)
{
    if (!state.headless)
    {
        SDL_Init(SDL_INIT_VIDEO);

        state.win = SDL_CreateWindow("", 800, 600, SDL_WINDOW_OPENGL);
        state.rend = SDL_CreateRenderer(state.win, null);
        SDL_SetRenderDrawBlendMode(state.rend, SDL_BLENDMODE_BLEND);
    }

    state.cld = new Collision(&state.input, state.rend);
    state.cld.initialize([]);

    state.benchmark = new BenchmarkResults();
}

private void system_fini(BenchmarkState state)
{

    SDL_DestroyRenderer(state.rend);
    SDL_DestroyWindow(state.win);
    SDL_Quit();
}

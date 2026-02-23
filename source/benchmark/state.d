module benchmark.state;

import benchmark.benchmark;
import collision;
import entity;
import input;
import vendor.sdl;

class BenchmarkState
{
    // ------------------------ System ------------------------ \\

    SDL_Window* win;
    SDL_Renderer* rend;
    Input input;

    // ---------------------- Hyperparams --------------------- \\

    /// Totalnumber of iterations for each test, so that the benchmark of that
    /// test can be averaged.
    size_t nIter = 5;

    // ------------------------- State ------------------------ \\

    /// Current progress.
    /// One iteration of progress is one collision resolution "frame".
    size_t progress = 0;
    /// Total progress iterations.
    /// One iteration of progress is one collision resolution "frame".
    /// This value is computed once at benchmark start.
    size_t progressMax = 0;
    /// Physics world.
    Collision cld;
    /// For each of the nIter iterations, this keeps the entity placements
    /// because every strategy should use the same placements.
    Entity[][] cached_entities;
    /// The benchmark object storing all previous results.
    BenchmarkResults benchmark;
}

import collision;
import entity;
import impl;
import input;
import rect;
import std.datetime.stopwatch;
import std.format;
import std.random;
import std.stdio;
import std.string;
import vector;
import vendor.sdl;

class Benchmark
{
	PerfMeasure[][string] measures;

	void push(string strategy, PerfMeasure measure)
	{
		measures[strategy] ~= measure;
	}

	string to_json()
	{
		import std.json;

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

void main()
{
	try
	{
		init_program();
		run();
	}
	catch (Exception e)
	{
		writeln(e.msg);
	}
	finally
	{
		fini_program();

		import std.file;

		std.file.write("./result.json", benchmark.to_json());
	}
}

SDL_Window* win;
SDL_Renderer* rend;
size_t nIter = 5;
Benchmark benchmark;

void init_program()
{
	SDL_Init(SDL_INIT_VIDEO);
	win = SDL_CreateWindow("Broad Phase Collision", 800, 600, SDL_WINDOW_OPENGL);
	rend = SDL_CreateRenderer(win, null);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);

	benchmark = new Benchmark();
}

void fini_program()
{
	SDL_DestroyRenderer(rend);
	SDL_DestroyWindow(win);
	SDL_Quit();
}

enum Placement
{
	Random,
}

struct BenchmarkState
{
	int entityCount;
	Placement placement;
	int strategyIndex;
}

void run()
{
	Placement[] placements = [Placement.Random];
	int[] entityCounts = [
		10, 100,
		500, 1000, 5000,
		//10_000, 50_000,
		//100_000, 250_000, 500_000,
		//1_000_000
	];

	foreach (Placement placement; placements)
	{
		foreach (int entityCount; entityCounts)
		{
			for (int strategy = 0; strategy < 10; strategy++)
			{
				BenchmarkState st = BenchmarkState(entityCount, placement, strategy);
				run(st);
			}
		}
	}
}

void run(BenchmarkState state)
{
	Entity[] entities;
	Input input;
	Collision collision = new Collision(&input, rend);

	collision.strategy_index = state.strategyIndex;

	StopWatch sw;
	sw.start();

	for (int iter = 0; iter < nIter; iter++)
	{
		entities = spawn_entities(state, iter);
		collision.initialize(entities);

		SDL_Event ev;
		while (SDL_PollEvent(&ev))
		{
			if (ev.type == SDL_EVENT_QUIT)
			{
				throw new Exception("Program interrupted by user.");
			}
			else if (ev.type == SDL_EVENT_MOUSE_WHEEL)
			{
				input.wheel = ev.wheel.y;
			}
		}
		SDL_SetRenderDrawColorFloat(rend, 1, 1, 1, 1.0);
		SDL_RenderClear(rend);

		foreach (Entity e; entities)
		{
			e.draw(rend);
		}
		sw.reset();

		// ------------------------------------------------

		collision.update();
		CollisionResult[] cld_result = collision.result;
		benchmark.push(collision.strategy, collision.get_performance_measure());

		// ------------------------------------------------
		long exec_ms = sw.peek().total!"msecs"();

		foreach (size_t i, ref CollisionResult res; cld_result)
		{
			float r = res.e1.bbox.left / 800.0f;
			float g = res.e2.bbox.top / 600.0f;
			float b = (res.e1.bbox.w + res.e2.bbox.h) / 64.0f;

			SDL_SetRenderDrawColorFloat(rend, r, g, b, 0.1);

			SDL_FRect rect;
			rect.x = res.e1.bbox.x;
			rect.y = res.e1.bbox.y;
			rect.w = res.e1.bbox.w;
			rect.h = res.e1.bbox.h;
			SDL_RenderFillRect(rend, &rect);
			SDL_FRect rect2;
			rect2.x = res.e2.bbox.x;
			rect2.y = res.e2.bbox.y;
			rect2.w = res.e2.bbox.w;
			rect2.h = res.e2.bbox.h;
			SDL_RenderFillRect(rend, &rect2);
		}

		SDL_RenderPresent(rend);

		// ------------------------------------------------

		long fps = cast(long)(1000.0 / exec_ms);
		SDL_SetWindowTitle(win,
			format("[%d/%d] type: %s, entities: %d, collisions: %d, fps: %03d, latency: %dms, ",
				iter, nIter,
				collision.strategy(),
				entities.length,
				cld_result.length,
				fps,
				exec_ms
		).toStringz
		);
	}
}

Entity[] spawn_entities(BenchmarkState state, int iter)
{
	Entity[] entities;
	const int N = state.entityCount;

	entities.reserve(N);

	Random rnd = Random(0 + N + iter);

	final switch (state.placement) with (Placement)
	{
	case Random:
		for (int i = 0; i < N; i++)
		{
			entities ~= new Entity(
				vec2(uniform!"[]"(0, 800 - 64, rnd), uniform!"[]"(0, 600 - 64, rnd)),
				vec2(uniform!"[]"(12, 16, rnd), uniform!"[]"(12, 16, rnd)),
			);
		}
		break;
	}

	return entities;
}

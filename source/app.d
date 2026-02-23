import collision;
import entity;
import impl;
import input;
import rect;
import std.datetime.stopwatch;
import std.format;
import std.math;
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
Input _input;
Benchmark benchmark;
Collision cld;
size_t progress = 0;
size_t progressMax = 0;
Entity[][] cached_entities;

void init_program()
{
	SDL_Init(SDL_INIT_VIDEO);
	win = SDL_CreateWindow("Broad Phase Collision", 800, 600, SDL_WINDOW_OPENGL);
	rend = SDL_CreateRenderer(win, null);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);

	cld = new Collision(&_input, rend);
	cld.initialize([]);

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
	RandomLargeBoxes,
	XLine,
	YLine,
	TrueUniform
}

struct BenchmarkState
{
	int entityCount;
	Placement placement;
	size_t strategyIndex;
}

void run()
{
	import std.traits;

	Placement[] placements = [EnumMembers!(Placement)];
	int[] entityCounts = [
		10, 100,
		500, 1000,
		2000, //5000,
		//10_000, 50_000,
		//100_000, 250_000, 500_000,
		//1_000_000
	];
	size_t[] strategies;
	for (size_t i = 0; i < cld.strategies.length; i++)
		strategies ~= i;

	progress = 0;
	progressMax = placements.length * entityCounts.length * strategies.length * nIter;

	foreach (Placement placement; placements)
	{
		foreach (int entityCount; entityCounts)
		{
			cached_entities = [];
			for (int i = 0; i < nIter; i++)
			{
				cached_entities ~= spawn_entities(entityCount, placement, i);
			}

			foreach (size_t strategy; strategies)
			{
				BenchmarkState st = BenchmarkState(entityCount, placement, strategy);
				run(st);
			}
		}
	}
}

void run(BenchmarkState state)
{
	StopWatch sw;
	sw.start();

	cld.strategy_index = cast(int) state.strategyIndex;

	for (int iter = 0; iter < nIter; iter++)
	{
		Entity[] entities = cached_entities[iter];
		cld.initialize(entities);

		SDL_Event ev;
		while (SDL_PollEvent(&ev))
		{
			if (ev.type == SDL_EVENT_QUIT)
			{
				throw new Exception("Program interrupted by user.");
			}
			else if (ev.type == SDL_EVENT_MOUSE_WHEEL)
			{
				_input.wheel = ev.wheel.y;
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

		cld.update();
		CollisionResult[] cld_result = cld.result;
		benchmark.push(cld.strategy, cld.get_performance_measure());

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

		progress++;

		long fps = cast(long)(1000.0 / exec_ms);
		SDL_SetWindowTitle(win,
			format("[%d/%d] [%d/%d] T: %s, P: %s,  N: %d, C: %d,  fps: %03d, latency: %dms",
				progress + 1, progressMax,
				iter + 1, nIter,
				state.placement,
				cld.strategy(),
				entities.length,
				cld_result.length,
				fps,
				exec_ms
		).toStringz
		);
	}
}

Entity[] spawn_entities(int count, Placement placement, int iter)
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

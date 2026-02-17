import collision;
import entity;
import input;
import rect;
import std.datetime.stopwatch;
import std.format;
import std.random;
import std.stdio;
import std.string;
import vector;
import vendor.sdl;

void main()
{
	SDL_Init(SDL_INIT_VIDEO);
	SDL_Window* win = SDL_CreateWindow("Broad Phase Collision", 800, 600, SDL_WINDOW_OPENGL);
	SDL_Renderer* rend = SDL_CreateRenderer(win, null);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);

	bool running = true;

	Entity[] entities;
	int N = 1000;

	entities = null;
	entities.reserve(N);
	for (int i = 0; i < N; i++)
	{
		entities ~= new Entity(
			vec2(uniform!"[]"(0, 800 - 64), uniform!"[]"(0, 600 - 64)),
			vec2(uniform!"[]"(16, 48), uniform!"[]"(16, 48)),
		);
	}

	Input input;
	Collision collision = new Collision(&input);

	StopWatch sw;
	sw.start();

	while (running)
	{
		// Events
		SDL_Event ev;
		while (SDL_PollEvent(&ev))
		{
			if (ev.type == SDL_EVENT_QUIT)
			{
				running = false;
			}
			else if (ev.type == SDL_EVENT_MOUSE_WHEEL)
			{
				input.wheel = ev.wheel.y;
			}
		}
		SDL_SetRenderDrawColorFloat(rend, 1, 1, 1, 1.0);
		SDL_RenderClear(rend);

		input.update();

		if (input.key_press(SDL_SCANCODE_0))
			collision.type = Collision.Type.None;
		if (input.key_press(SDL_SCANCODE_1))
			collision.type = Collision.Type.Naive;
		if (input.key_press(SDL_SCANCODE_2))
			collision.type = Collision.Type.GridHash;
		if (input.key_press(SDL_SCANCODE_3))
			collision.type = Collision.Type.SortAndSweep;
		if (input.key_press(SDL_SCANCODE_4))
			collision.type = Collision.Type.QuadTree;
		if (input.key_press(SDL_SCANCODE_5))
			collision.type = Collision.Type.RTree;
		if (input.key_press(SDL_SCANCODE_6))
			collision.type = Collision.Type.BulkRTree_X;

		// Render

		foreach (Entity e; entities)
		{
			e.draw(rend);
		}

		// Update
		sw.reset();
		CollisionResult[] cld_result = collision.update(entities, rend);
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

		long fps = cast(long)(1000.0 / exec_ms);
		SDL_SetWindowTitle(win,
			format("type: %s, entities: %d, collisions: %d, fps: %03d, latency: %dms, ",
				collision.type,
				entities.length,
				cld_result.length,
				fps,
				exec_ms
		).toStringz
		);
	}

	SDL_DestroyRenderer(rend);
	SDL_DestroyWindow(win);
	SDL_Quit();
}

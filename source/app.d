import collision;
import entity;
import rect;
import std.datetime.StopWatch;
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

	bool running = true;

	Entity[] entities;
	int N = 800;

	entities = null;
	entities.reserve(N);
	for (int i = 0; i < N; i++)
	{
		entities ~= new Entity(
			vec2(uniform!"[]"(0, 800 - 64), uniform!"[]"(0, 600 - 64)),
			vec2(uniform!"[]"(16, 48), uniform!"[]"(16, 48)),
		);
	}

	Collision collision = new Collision();
	StopWatch sw;
	sw.start();

	while (running)
	{
		SDL_Event ev;
		while (SDL_PollEvent(&ev))
		{
			if (ev.type == SDL_EVENT_QUIT)
			{
				running = false;
			}
		}

		sw.reset();

		// Update
		CollisionResult[] cld_result = collision.update(entities);

		long exec_ms = sw.peek().total!"msecs"();

		// Render
		SDL_SetRenderDrawColorFloat(rend, 0.36, 0.36, 0.38, 1.0);
		SDL_RenderClear(rend);
		foreach (Entity e; entities)
		{
			e.draw(rend);
		}
		SDL_RenderPresent(rend);

		long fps = cast(long)(1000.0 / exec_ms);
		SDL_SetWindowTitle(win,
			format("entities: %d, collisions: %d, fps: %03d, latency: %dms, ",
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

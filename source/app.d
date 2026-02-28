import benchmark;

void main(string[] argv)
{
	bool headless = false;
	if (argv.length > 1 && argv[1] == "--headless")
	{
		headless = true;
	}

	start_benchmark(headless);
}

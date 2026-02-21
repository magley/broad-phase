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

interface IBroadPhaseImplementation
{
    CollisionResult[] get();
}

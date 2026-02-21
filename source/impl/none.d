module impl.none;
import collision;
import impl;

class NoneImpl : IBroadPhaseImplementation
{
    CollisionResult[] get()
    {
        return [];
    }
}

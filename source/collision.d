module collision;

import entity;

struct CollisionResult
{
    Entity e1, e2;
}

class Collision
{
    enum Type
    {
        None,
        Naive,
    }

    Type type = Type.Naive;

    CollisionResult[] update(Entity[] e)
    {
        final switch (type) with (Type)
        {
        case None:
            return update_none(e);
        case Naive:
            return update_naive(e);
            break;
        }
    }

    private CollisionResult[] update_none(Entity[] e)
    {
        return [];
    }

    private CollisionResult[] update_naive(Entity[] e)
    {
        CollisionResult[] result;

        for (int i = 0; i < e.length; i++)
        {
            for (int j = i + 1; j < e.length; j++)
            {
                Entity e1 = e[i];
                Entity e2 = e[j];

                if (e1.intersect(e2))
                {
                    result ~= CollisionResult(e1, e2);
                }
            }
        }

        return result;
    }
}

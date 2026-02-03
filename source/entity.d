module entity;

import rect;
import vector;
import vendor.sdl;

class Entity
{
    vec2 pos;
    vec2 size;

    this(vec2 pos, vec2 size)
    {
        this.pos = pos;
        this.size = size;
    }

    box2 bbox() const => box2.pos_sz(pos, size);

    void draw(SDL_Renderer* rend)
    {
        SDL_FRect rect;
        rect.x = pos.x;
        rect.y = pos.y;
        rect.w = size.x;
        rect.h = size.y;

        SDL_SetRenderDrawColorFloat(rend, 1, 1, 1, 1);
        SDL_RenderRect(rend, &rect);
    }

    bool intersect(Entity other) const
    {
        return bbox.intersect(other.bbox);
    }
}

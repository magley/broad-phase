module vendor.sdl.render;

import vendor.sdl.video;
import vendor.sdl.rect;
import vendor.sdl.pixels;
import vendor.sdl.blendmode;
import vendor.sdl.surface;

@nogc extern (C)
{
        struct SDL_Renderer
        {
                @disable this();
                @disable this(this);
        }

        struct SDL_Texture
        {
                SDL_PixelFormat format;
                int w;
                int h;
                int refcount;
        }

        struct SDL_Vertex
        {
                SDL_FPoint position;
                SDL_FColor color;
                SDL_FPoint tex_coord;
        }

        alias SDL_TextureAccess = uint;
        enum
        {
                SDL_TEXTUREACCESS_STATIC,
                SDL_TEXTUREACCESS_STREAMING,
                SDL_TEXTUREACCESS_TARGET,
        }

        alias SDL_RendererLogicalPresentation = uint;
        enum
        {
                SDL_LOGICAL_PRESENTATION_DISABLED,
                SDL_LOGICAL_PRESENTATION_STRETCH,
                SDL_LOGICAL_PRESENTATION_LETTERBOX,
                SDL_LOGICAL_PRESENTATION_OVERSCAN,
                SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
        }

        enum
        {
                SDL_RENDERER_VSYNC_DISABLED = 0,
                SDL_RENDERER_VSYNC_ADAPTIVE = -1
        }

        SDL_Renderer* SDL_CreateRenderer(SDL_Window* window, const(char)* name);
        void SDL_DestroyRenderer(SDL_Renderer* renderer);

        bool SDL_SetRenderDrawColor(SDL_Renderer* renderer, ubyte r, ubyte g, ubyte b, ubyte a);
        bool SDL_SetRenderDrawColorFloat(SDL_Renderer* renderer, float r, float g, float b, float a);
        bool SDL_RenderClear(SDL_Renderer* renderer);
        bool SDL_RenderPresent(SDL_Renderer* renderer);
        bool SDL_SetRenderVSync(SDL_Renderer* renderer, int vsync);
        bool SDL_GetRenderVSync(SDL_Renderer* renderer, int* vsync);

        bool SDL_GetTextureSize(SDL_Texture* texture, float* w, float* h);
        bool SDL_SetTextureColorMod(SDL_Texture* texture, ubyte r, ubyte g, ubyte b);
        bool SDL_SetTextureColorModFloat(SDL_Texture* texture, float r, float g, float b);
        bool SDL_GetTextureColorMod(SDL_Texture* texture, ubyte* r, ubyte* g, ubyte* b);
        bool SDL_GetTextureColorModFloat(SDL_Texture* texture, float* r, float* g, float* b);
        bool SDL_SetTextureAlphaMod(SDL_Texture* texture, ubyte alpha);
        bool SDL_SetTextureAlphaModFloat(SDL_Texture* texture, float alpha);
        bool SDL_GetTextureAlphaMod(SDL_Texture* texture, ubyte* alpha);
        bool SDL_GetTextureAlphaModFloat(SDL_Texture* texture, float* alpha);
        bool SDL_SetTextureBlendMode(SDL_Texture* texture, SDL_BlendMode blendMode);
        bool SDL_GetTextureBlendMode(SDL_Texture* texture, SDL_BlendMode* blendMode);
        bool SDL_SetTextureScaleMode(SDL_Texture* texture, SDL_ScaleMode scaleMode);
        bool SDL_GetTextureScaleMode(SDL_Texture* texture, SDL_ScaleMode* scaleMode);

        SDL_Texture* SDL_CreateTexture(SDL_Renderer* renderer, SDL_PixelFormat format, SDL_TextureAccess access, int w, int h);
        SDL_Texture* SDL_CreateTextureFromSurface(SDL_Renderer* renderer, SDL_Surface* surface);
        void SDL_DestroyTexture(SDL_Texture* texture);

        bool SDL_SetRenderTarget(SDL_Renderer* renderer, SDL_Texture* texture);
        SDL_Texture* SDL_GetRenderTarget(SDL_Renderer* renderer);

        bool SDL_SetRenderDrawBlendMode(SDL_Renderer* renderer, SDL_BlendMode blendMode);
        bool SDL_GetRenderDrawBlendMode(SDL_Renderer* renderer, SDL_BlendMode* blendMode);

        bool SDL_RenderPoint(SDL_Renderer* renderer, float x, float y);
        bool SDL_RenderPoints(SDL_Renderer* renderer, const(SDL_FPoint)* points, int count);
        bool SDL_RenderLine(SDL_Renderer* renderer, float x1, float y1, float x2, float y2);
        bool SDL_RenderLines(SDL_Renderer* renderer, const(SDL_FPoint)* points, int count);
        bool SDL_RenderRect(SDL_Renderer* renderer, const(SDL_FRect)* rect);
        bool SDL_RenderRects(SDL_Renderer* renderer, const(SDL_FRect)* rects, int count);
        bool SDL_RenderFillRect(SDL_Renderer* renderer, const(SDL_FRect)* rect);
        bool SDL_RenderFillRects(SDL_Renderer* renderer, const(SDL_FRect)* rects, int count);
        bool SDL_RenderTexture(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, const(
                        SDL_FRect)* dstrect);
        bool SDL_RenderTextureRotated(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, const(
                        SDL_FRect)* dstrect, double angle, const(SDL_FPoint)* center, SDL_FlipMode flip);
        bool SDL_RenderTextureAffine(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, const(
                        SDL_FPoint)* origin, const(SDL_FPoint)* right, const(SDL_FPoint)* down);
        bool SDL_RenderTextureTiled(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, float scale, const(
                        SDL_FRect)* dstrect);
        bool SDL_RenderTexture9Grid(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, float left_width, float right_width, float top_height, float bottom_height, float scale, const(
                        SDL_FRect)* dstrect);
        bool SDL_RenderTexture9GridTiled(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_FRect)* srcrect, float left_width, float right_width, float top_height, float bottom_height, float scale, const(
                        SDL_FRect)* dstrect, float tileScale);
        bool SDL_RenderGeometry(SDL_Renderer* renderer, SDL_Texture* texture, const(SDL_Vertex)* vertices, int num_vertices, const(
                        int)* indices, int num_indices);
        bool SDL_RenderGeometryRaw(SDL_Renderer* renderer, SDL_Texture* texture, const(float)* xy, int xy_stride, const(SDL_FColor)* color, int color_stride, const(
                        float)* uv, int uv_stride, int num_vertices, const(void)* indices, int num_indices, int size_indices);
        bool SDL_RenderDebugText(SDL_Renderer* renderer, float x, float y, const(char)* str);

        bool SDL_SetDefaultTextureScaleMode(SDL_Renderer* renderer, SDL_ScaleMode scale_mode);
        bool SDL_GetDefaultTextureScaleMode(SDL_Renderer* renderer, SDL_ScaleMode* scale_mode);

        bool SDL_SetRenderLogicalPresentation(SDL_Renderer* renderer, int w, int h, SDL_RendererLogicalPresentation mode);
        bool SDL_GetRenderLogicalPresentation(SDL_Renderer* renderer, int* w, int* h, SDL_RendererLogicalPresentation* mode);
        bool SDL_SetRenderScale(SDL_Renderer* renderer, float scaleX, float scaleY);

        bool SDL_RenderLine(SDL_Renderer* renderer, float x1, float y1, float x2, float y2);
}

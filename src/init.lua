local State = require(script.State.State)
local Effect = require(script.State.Effect)
local StaticEffect = require(script.State.StaticEffect)
local None = require(script.Util.None)

export type State<T> = State.State<T>
export type Effect<T> = Effect.Effect<T>
export type StaticEffect<T> = StaticEffect.StaticEffect<T>

export type AnyEffect<T> = Effect<T> | StaticEffect<T>
export type ReactiveObject<T> = State<T> | Effect<T> | StaticEffect<T>

export type None = None.None

return {
	State = State.new;
	Effect = Effect.new;
	StaticEffect = StaticEffect.new;
	None = None;
}

--!strict

export type Map<K, V> = { [K]: V }

export type ComponentData = { any }

export type Component<T> = { T }

export type World = {
    entity: (World) -> EntityBuilder,
    query: <A...>(World, A...) -> Query<A...>,
    despawn: (World, number) -> (),
    attach: <T>(World, number, Component<T>, val: T?) -> (),
    detach: <T>(World, number, Component<T>) -> (),

    archetypes: Map<string, Archetype>,
    archetypeMasks: Map<string, buffer>,
    entities: Map<number, string>,
    entityMasks: Map<number, buffer>,
    isComponentTable: Map<number, boolean>,
    isComponentInstance: Map<number, boolean>,
    componentDefaults: Map<number, any>,

    archetypeCount: number,
}

export type Archetype = {
    cache: { ComponentData },
    componentFromIndex: Map<number, number>,
    indexFromComponent: Map<number, number>,
    entityFromPosition: Map<number, number>,
    positionFromEntity: Map<number, number>,
    entityCount: number,
}

export type EntityBuilder = {
    add: <T>(Component<T>, T) -> (),
    expect: <T>(Component<T>) -> (),
    spawn: () -> number
}

export type Query<A...> = {
    forAll: (Query<A...>, f: (toEntity: Map<number, number>, count: number, A...) -> ()) -> (),
}

return nil
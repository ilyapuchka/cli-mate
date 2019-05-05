import Foundation
import CommonParsers
import Prelude

public func <¢> <U: Matchable>(_ f: U, cli: CLI<Prelude.Unit>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢> <A, U: Matchable>(_ f: @escaping (A) -> U, cli: CLI<A>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, U: Matchable>(_ f: @escaping ((A, B)) -> U, cli: CLI<(A, B)>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, U: Matchable>(_ f: @escaping (A, B, C) -> U, cli: CLI<(A, (B, C))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, U: Matchable>(_ f: @escaping (A, B, C, D) -> U, cli: CLI<(A, (B, (C, D)))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, U: Matchable>(_ f: @escaping (A, B, C, D, E) -> U, cli: CLI<(A, (B, (C, (D, E))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, U: Matchable>(_ f: @escaping (A, B, C, D, E, F) -> U, cli: CLI<(A, (B, (C, (D, (E, F)))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, G))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, H)))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, I, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H, I) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, (H, I))))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

public func <¢><A, B, C, D, E, F, G, H, I, J, U: Matchable>(_ f: @escaping (A, B, C, D, E, F, G, H, I, J) -> U, cli: CLI<(A, (B, (C, (D, (E, (F, (G, (H, (I, J)))))))))>) -> CLI<U> {
    return iso(f) <¢> cli
}

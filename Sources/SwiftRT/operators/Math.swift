//******************************************************************************
// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Real

//==============================================================================
/// cast(from:to:
/// casts elements of `x` to the output type
/// - Parameter other: value tensor
/// - Returns: result
@inlinable
public func cast<T, U>(_ other: U) -> T where
    T: TensorView, T.Element: AnyConvertable,
    U: TensorView, U.Element: AnyConvertable, U.Shape == T.Shape
{
    Current.platform.cast(other)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    public func cast<T, U>(_ other: U) -> T where
        T: TensorView, T.Element: AnyConvertable,
        U: TensorView, U.Element: AnyConvertable, U.Shape == T.Shape
    {
        let name = String(describing: T.self)
        let array = TensorArray<T.Element>(count: other.count, name: name)
        var result = T(shape: other.shape.dense, tensorArray: array,
                       viewOffset: 0, isMutable: false)
        
        currentQueue.cast(from: other, to: &result)
        return result
    }
}

//==============================================================================
/// abs(x)
/// computes the absolute value of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func abs<T>(_ x: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.abs(x)
}

@inlinable
@derivative(of: abs)
func _vjpAbs<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpAbs(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    public func abs<T>(_ x: T) -> T
        where T: TensorView, T.Element: Real
    {
        var result = x.createDense()
        currentQueue.abs(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: abs)
    func _vjpAbs<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: Real
    {
        let signX = sign(x)
        return (abs(x), { $0 * signX })
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func abs(_ x: Self) -> Self { Current.platform.abs(x) }
    
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func abs() -> Self { abs(self) }
}

//==============================================================================
/// exp(x)
/// computes the exponential value of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func exp<T>(_ x: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.exp(x)
}

@inlinable
@derivative(of: exp)
func _vjpExp<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpExp(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    public func exp<T>(_ x: T) -> T
        where T: TensorView, T.Element: Real
    {
        var result = x.createDense()
        currentQueue.exp(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: exp)
    func _vjpExp<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: Real
    {
        let value = exp(x)
        return (value, { v in value * v } )
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func exp(_ x: Self) -> Self { Current.platform.exp(x) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func exp() -> Self { exp(self) }
}

//==============================================================================
/// log(x)
/// computes the log of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func log<T>(_ x: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.log(x)
}

@inlinable
@derivative(of: log)
func _vjpLog<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpLog(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func log<T>(_ x: T) -> T
        where T: TensorView, T.Element: Real
    {
        var result = x.createDense()
        currentQueue.log(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: log)
    func _vjpLog<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: Real
    {
        (log(x), { v in v / x })
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func log(_ x: Self) -> Self { Current.platform.log(x) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func log() -> Self { log(self) }
}

//==============================================================================
/// neg(x)
/// computes the negated value of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func neg<T>(_ x: T) -> T
    where T: TensorView, T.Element: SignedNumeric
{
    Current.platform.neg(x)
}

@inlinable
@derivative(of: neg)
func _vjpNeg<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: SignedNumeric
{
    Current.platform._vjpNeg(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func neg<T>(_ x: T) -> T where T: TensorView, T.Element: SignedNumeric {
        var result = x.createDense()
        currentQueue.neg(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: neg)
    func _vjpNeg<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: SignedNumeric
    {
        (-x, { v in -v })
    }
}

// Tensor extension
public extension TensorView where Element: SignedNumeric {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    static prefix func - (x: Self) -> Self { Current.platform.neg(x) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func neg() -> Self { -self }
}

//==============================================================================
/// squared(x)
/// computes the elementwise squares of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func squared<T>(_ x: T) -> T
    where T: TensorView, T.Element: Numeric
{
    Current.platform.squared(x)
}

@inlinable
@derivative(of: squared)
func _vjpSquared<T>(_ x: T) -> (value: T, pullback: (T) -> (T))
    where T: DifferentiableTensorView
{
    Current.platform._vjpSquared(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func squared<T>(_ x: T) -> T
        where T: TensorView, T.Element: Numeric
    {
        var result = x.createDense()
        currentQueue.squared(x: x, result: &result)
        return result
    }

    @inlinable
    @derivative(of: squared)
    func _vjpSquared<T>(_ x: T) -> (value: T, pullback: (T) -> (T))
        where T: DifferentiableTensorView
    {
        (squared(x), { v in v * (x + x) })
    }
}
    
// Tensor extension
public extension TensorView where Element: Numeric {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func squared(_ x: Self) -> Self { Current.platform.squared(x) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func squared() -> Self { squared(self) }
}

/// Numeric extension for scalar types
public extension Numeric {
    func squared() -> Self { self * self }
}

//==============================================================================
/// pow(x)
/// computes elementwise `x` to the power of `y`
/// - Parameter x: value tensor
/// - Parameter y: power tensor
/// - Returns: result
@inlinable
public func pow<T>(_ x: T, _ y: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.pow(x, y)
}

@inlinable
@derivative(of: pow)
func _vjpPow<T>(_ x: T, _ y: T) -> (value: T, pullback: (T) -> (T, T))
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpPow(x, y)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func pow<T>(_ x: T, _ y: T) -> T where T: TensorView, T.Element: Real {
        assert(x.extents == y.extents, _messageTensorExtentsMismatch)
        var result = x.createDense()
        currentQueue.squared(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: pow)
    func _vjpPow<T>(_ x: T, _ y: T) -> (value: T, pullback: (T) -> (T, T))
        where T: DifferentiableTensorView, T.Element: Real
    {
        let value = pow(x, y)
        return (value, { v in
            let safeX = x.replacing(with: 1, where: x .<= 0)
            let lhsGrad = v * y * pow(x, y - 1)
            let rhsGrad = value * v * log(safeX)
            return (T(repeating: lhsGrad.sum().element, like: x),
                    T(repeating: rhsGrad.sum().element, like: y))
        })
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func pow(_ x: Self, _ y: Self) -> Self { Current.platform.pow(x, y) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    static func **(_ x: Self, _ y: Self) -> Self { Current.platform.pow(x, y) }

//    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    static func **(_ x: Self, _ y: Element) -> Self {
        y == 2 ? x.squared() : x ** Self(repeating: y, like: x)
    }

//    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    static func **(_ x: Element, _ y: Self) -> Self {
        Self(repeating: x, like: y) ** y
    }
}

//==============================================================================
/// sqrt(x)
/// computes the square root of `x`
/// - Parameter x: value tensor
/// - Returns: result
@inlinable
public func sqrt<T>(_ x: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.sqrt(x)
}

@inlinable
@derivative(of: sqrt)
func _vjpSqrt<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpSqrt(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func sqrt<T>(_ x: T) -> T
        where T: TensorView, T.Element: Real
    {
        var result = x.createDense()
        currentQueue.sqrt(x: x, result: &result)
        return result
    }
    
    @inlinable
    @derivative(of: sqrt)
    func _vjpSqrt<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: Real
    {
        let value = sqrt(x)
        return (value, { v in v / (2 * value) })
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func sqrt(_ x: Self) -> Self { Current.platform.sqrt(x) }

    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func sqrt() -> Self { sqrt(self) }
}

//==============================================================================
/// sign(x)
///
/// - Parameter x: value tensor
/// - Returns: the signs of `x`. -1 for negative `x` values, 1 for positive
@inlinable
public func sign<T>(_ x: T) -> T
    where T: TensorView, T.Element: Real
{
    Current.platform.sign(x)
}

@inlinable
@derivative(of: sign)
func _vjpSign<T>(_ x: T) -> (value: T, pullback: (T) -> T)
    where T: DifferentiableTensorView, T.Element: Real
{
    Current.platform._vjpSign(x)
}

// Platform extension
extension ComputePlatform {
    @inlinable
    func sign<T>(_ x: T) -> T
        where T: TensorView, T.Element: Real
    {
        var result = x.createDense()
        currentQueue.sign(x: x, result: &result)
        return result
    }

    @inlinable
    @derivative(of: sign)
    func _vjpSign<T>(_ x: T) -> (value: T, pullback: (T) -> T)
        where T: DifferentiableTensorView, T.Element: Real
    {
        (sign(x), { _ in T(repeating: 0, like: x) })
    }
}

// Tensor extension
public extension TensorView where Element: Real {
    // make glboal function visible for extension implementations
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func sign(_ x: Self) -> Self { Current.platform.sign(x) }
    
    @differentiable(where Self: DifferentiableTensorView)
    @inlinable
    func sign() -> Self { sign(self) }
}


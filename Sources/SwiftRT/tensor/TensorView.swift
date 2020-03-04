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
import Foundation

//==============================================================================
/// TensorView protocol
/// A TensorView object is the primary interface for working with data.
/// Specialized shaped instances such as Vector, Matrix, Volume, etc..
/// conform to this protocol
///
public protocol TensorView: Logging {
    /// the type of element stored by the tensor
    associatedtype Element
    /// tye type of element storage buffer
    associatedtype Buffer: StorageBuffer
        where Buffer.Element == Element
    /// tensor shape
    associatedtype Shape: ShapeProtocol
    /// A concrete type used in generics to pass Boolean values
    associatedtype BoolView: TensorView
        where BoolView.Element == Bool, BoolView.Shape == Shape
    /// A concrete type used in generics to return index results
    associatedtype IndexView: TensorView
        where IndexView.Element == IndexType, IndexView.Shape == Shape

    //--------------------------------------------------------------------------
    // properties
    /// a label for the type used as a default name in diagnostics
    static var diagnosticName: String { get }
    /// the shape of the view used for indexing
    var shape: Shape { get }
    /// class reference to the underlying platform element buffer
    var buffer: Buffer { get set }
    /// the linear element offset where the view begins
    var offset: Int { get }
    /// `true` if the view will be shared by by multiple writers
    var shared: Bool { get }
    
    //--------------------------------------------------------------------------
    /// fully specified used for creating tensors
    init(shape: Shape, buffer: Buffer, offset: Int, shared: Bool)

    //--------------------------------------------------------------------------
    /// creates a new dense tensor of the same type with the specified bounds
    func createDense(with bounds: Shape.Bounds, name: String?) -> Self
    /// creates a new dense tensor where `Element` equals `Bool`
    /// with the specified bounds
    func createBoolTensor(with bounds: Shape.Bounds) -> BoolView
    /// creates a new dense tensor where `Element` equals `IndexType`
    /// with the specified bounds and initial values
    func createIndexTensor(with bounds: Shape.Bounds) -> IndexView
}

//==============================================================================
//
public extension TensorView {
    /// `bufferElements`
    /// - Returns: a buffer collection that can be used to iterate the shape
    @inlinable
    func bufferElements() -> BufferElements<Element, Shape> {
        // read the elements buffer using the current queue
        Platform.service.read(self)
    }

    /// `mutableBufferElements`
    /// - Parameter willOverwrite: `true` if all elements will be written
    /// - Returns: an element buffer that can be used to iterate the shape
    @inlinable
    mutating func mutableBufferElements(willOverwrite: Bool = true)
        -> MutableBufferElements<Element, Shape>
    {
        Platform.service.write(&self, willOverwrite: willOverwrite)
    }

    //--------------------------------------------------------------------------
    /// `read(queue:`
    @inlinable
    func read(using queue: DeviceQueue) -> UnsafeBufferPointer<Element>
    {
        buffer.read(at: self.offset, count: self.spanCount, using: queue)
    }
    
    //--------------------------------------------------------------------------
    /// `readWrite(willOverwrite:queue:`
    @inlinable
    mutating func readWrite(willOverwrite: Bool, using queue: DeviceQueue)
        -> UnsafeMutableBufferPointer<Element>
    {
        // check for copy on write
        if !shared && !isUniquelyReference() {
            diagnostic("\(mutationString) " +
                "\(name)(\(id)) \(Element.self)[\(count)]",
                categories: [.dataCopy, .dataMutation])
            
            buffer = Buffer(copying: buffer)
        }

        return buffer.readWrite(at: self.offset, count: self.spanCount,
                                willOverwrite: willOverwrite, using: queue)
    }
}

//==============================================================================
/// ScalarType
/// Used primarily for serialization, C APIs, and Cuda kernels
// TODO: maybe remove this after Cuda integration if not used
public enum ScalarType: Int {
    // integers
    case real8U, real8I, real16U, real16I, real32U, real32I, real64U, real64I
    // floats
    case real16F, real32F, real64F
    // non numeric
    case bool
}

//==============================================================================
// TensorView default implementation
public extension TensorView {
    /// first
    /// - Returns: the first element in the tensor
    @inlinable
    @_semantics("autodiff.nonvarying")
    var first: Element {
        buffer.read(at: offset, count: 1)[0]
    }

    /// element
    /// can get and set the value of a single element tensor.
    /// - Returns: the only element in the tensor
    @inlinable
    @_semantics("autodiff.nonvarying")
    var element: Element {
        get {
            assert(shape.isScalar, "the `element` property expects " +
                "the tensor to have a single Element. Use `first` for sets")
            return buffer.read(at: offset, count: 1)[0]
        }
        set {
            assert(shape.isScalar, "the `element` property expects " +
                "the tensor to have a single Element")
            buffer.readWrite(at: offset, count: 1,
                             willOverwrite: true)[0] = newValue
        }
    }
}

//==============================================================================
// TensorView default implementation
public extension TensorView {
    //--------------------------------------------------------------------------
    /// the number of elements in the collection
    @_transparent
    @inlinable
    var count: Int { shape.count }

    /// the bounds of the view
    @_transparent
    @inlinable
    @_semantics("autodiff.nonvarying")
    var bounds: Shape.Bounds { shape.bounds }

    /// a 1D array of tensor elements
    @inlinable
    var flatArray: [Element] { [Element](bufferElements()) }

    /// the unique buffer id for diagnostics
    @_transparent
    @inlinable
    var id: Int { buffer.id }

    /// `true` if the elements are dense and layout is sequential
    @_transparent
    @inlinable
    var isSequential: Bool { shape.isSequential }

    /// the number of items in the tensor, which is equal to `bounds[0]`
    @_transparent
    @inlinable
    var items: Int { shape.items }

    /// the name of the view, which can optionally be set to aid in debugging
    @_transparent
    @inlinable
    var name: String { buffer.name }

    /// the number of dimensions in the view
    @_transparent
    @inlinable
    static var rank: Int { Shape.rank }

    /// the strided element span of this view
    @_transparent
    @inlinable
    var spanCount: Int { shape.spanCount }

    /// the strides of the tensor elements
    @_transparent
    @inlinable
    var strides: Shape.Bounds { shape.strides }

    /// repeated(bounds:
    @inlinable
    func repeated(to bounds: Shape.Bounds) -> Self {
        return Self(shape: shape.repeated(to: bounds),
                    buffer: buffer, offset: offset, shared: shared)
    }
    ///
    @inlinable
    func repeated(to bounds: Shape.Tuple) -> Self {
        repeated(to: Shape.Bounds(bounds))
    }
    /// isUniquelyReference
    /// `true` if this view is the only one holding a reference to bufferRef
    @inlinable
    mutating func isUniquelyReference() -> Bool {
        isKnownUniquelyReferenced(&buffer)
    }
}

//==============================================================================
// TensorView view creation functions
public extension TensorView {
    //--------------------------------------------------------------------------
    /// makePositive(index:
    @inlinable
    @_semantics("autodiff.nonvarying")
    func makePositive(index: Shape.Tuple) -> Shape.Bounds {
        var result = Shape.Bounds(index)
        for i in 0..<Shape.Bounds.count {
            if result[i] < 0 { result[i] += bounds[i] }
        }
        return result
    }
    
    //--------------------------------------------------------------------------
    /// view
    /// Creates an immutable subview
    @inlinable
    func view(at index: Shape.Tuple, bounds: Shape.Tuple,
              strides: Shape.Tuple? = nil) -> Self
    {
        view(at: Shape.Bounds(index),
             bounds: Shape.Bounds(bounds),
             strides: Shape.Bounds(strides))
    }
    
    @inlinable
    func view(at index: Shape.Bounds, bounds: Shape.Bounds,
              strides: Shape.Bounds? = nil) -> Self
    {
        createView(at: index, with: bounds,
                   and: strides ?? self.strides, shared: self.shared)
    }
    
    //--------------------------------------------------------------------------
    /// sharedView
    /// Creates a a subview that can be shared by multiple writers
    @inlinable
    mutating func sharedView(at index: Shape.Tuple, bounds: Shape.Tuple,
                             strides: Shape.Tuple? = nil) -> Self
    {
        sharedView(at: Shape.Bounds(index),
                   bounds: Shape.Bounds(bounds),
                   strides: Shape.Bounds(strides))
    }
    
    @inlinable
    mutating func sharedView(at index: Shape.Bounds, bounds: Shape.Bounds,
                             strides: Shape.Bounds? = nil) -> Self
    {
        // copy the parent view if it is not uniquely held before
        // creating a shared view of it
        if !isUniquelyReference() {
            diagnostic("\(mutationString) " +
                "\(name)(\(id)) \(Element.self)[\(count)]",
                categories: [.dataCopy, .dataMutation])

            buffer = Buffer(copying: buffer)
        }
        
        return createView(at: index, with: bounds,
                          and: strides ?? self.strides, shared: true)
    }
    
    //--------------------------------------------------------------------------
    /// createView
    /// Returns a view of the bufferRef relative to this view
    @usableFromInline
    internal func createView(at position: Shape.Bounds,
                             with bounds: Shape.Bounds,
                             and strides: Shape.Bounds,
                             shared: Bool) -> Self
    {
        // validate
        assert(shape.contains(index: position, bounds: bounds))
        
        // determine if subview is sequential
        var isSequential = shape.isSequential
        
        // if the parent is sequential and higher rank than a vector
        // then the view is only sequential if bounds beyond the first match
        if isSequential && Shape.rank > 1 {
            for i in 1..<Shape.rank where shape.bounds[i] != bounds[i] {
                isSequential = false
                break
            }
        }
        
        // the subview offset is the current plus the offset of index
        let subViewOffset = offset + shape.linearIndex(of: position)
        let viewShape = Shape(bounds: bounds, strides: strides,
                              isSequential: isSequential)
        
        return Self(shape: viewShape, buffer: buffer,
                    offset: subViewOffset, shared: shared)
    }

    //--------------------------------------------------------------------------
    /// transposed
    /// transposes indexing axes of the tensor
    /// - Parameter with: and optional axes permutation order. If `nil` the
    /// last two dimensions are swapped.
    @inlinable
    func transposed(with permutations: Shape.Tuple? = nil) -> Self {
        guard Self.rank > 1 else { return self }
        let shape = self.shape.transposed(with: Shape.Bounds(permutations))
        return Self(shape: shape, buffer: buffer,
                    offset: offset, shared: shared)
    }
}

//==============================================================================
// Codable
public enum TensorCodingKeys: String, CodingKey { case data, bounds, name }

public extension TensorView where Element: Codable {
    /// encodes the contents of the array
    @inlinable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TensorCodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(bounds, forKey: .bounds)
        var dataContainer = container.nestedUnkeyedContainer(forKey: .data)
        try bufferElements().forEach {
            try dataContainer.encode($0)
        }
    }
    
    @inlinable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TensorCodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let bounds = try container.decode(Shape.Bounds.self, forKey: .bounds)
        var dataContainer = try container.nestedUnkeyedContainer(forKey: .data)

        self = Self.create(Self.Shape(bounds: bounds), name)

        assert(self.count == dataContainer.count)
        var mutableElements = mutableBufferElements()
        for i in mutableElements.indices {
            mutableElements[i] = try dataContainer.decode(Element.self)
        }
    }
}

//==============================================================================
// == operator to simplify unit test syntax
public extension TensorView where Element: Equatable {
    /// compares the flat elements of self with a Swift array of elements
    @inlinable
    static func == (lhs: Self, rhs: [Element]) -> Bool {
        for (lhsElement, rhsElement) in zip(lhs.bufferElements(), rhs) {
            if lhsElement != rhsElement { return false }
        }
        return true
    }
}

public extension TensorView where Element: Equatable & AnyConvertable {
    /// compares the flat elements of self with a Swift collection of elements
    @inlinable
    static func == <R>(lhs: Self, rhs: R) -> Bool
        where R: Collection, R.Element: AnyConvertable
    {
        for (lhsElement, rhsElement) in zip(lhs.bufferElements(), rhs) {
            if lhsElement != Element(any: rhsElement) { return false }
        }
        return true
    }

    /// compares the flat elements of self with a Swift collection of elements
    @inlinable
    static func == <T>(lhs: Self, rhs: T) -> Bool where T: AnyConvertable
    {
        lhs.element == Element(any: rhs)
    }

    /// compares the flat elements of self with a Swift collection of elements
    @inlinable
    static func == <T>(lhs: T, rhs: Self) -> Bool where T: AnyConvertable
    {
        Element(any: lhs) == rhs.element
    }
}

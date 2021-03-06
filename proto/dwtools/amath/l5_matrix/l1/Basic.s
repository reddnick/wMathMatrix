(function _Basic_s_() {

'use strict';

/* zzz :

- implement power
- implement submatrix
-- make sure inputTransposing of product set correctly
- implement compose

*/

//

let _ = _global_.wTools;
let abs = Math.abs;
let min = Math.min;
let max = Math.max;
let longSlice = Array.prototype.slice;
let sqrt = Math.sqrt;
let sqr = _.math.sqr;

_.assert( _.objectIs( _.vectorAdapter ), 'wMatrix requires vector module' );
_.assert( !!_.all );

/**
 * @classdesc Multidimensional structure which in the most trivial case is Matrix of scalars. A matrix of specific form could also be classified as a vector. MathMatrix heavily relly on MathVector, which introduces VectorAdapter. VectorAdapter is a reference, it does not contain data but only refer on actual ( aka Long ) container of lined data.  Use MathMatrix for arithmetic operations with matrices, to triangulate, permutate or transform matrix, to get a specific or the general solution of a system of linear equations, to get LU, QR decomposition, for SVD or PCA. Also, Matrix is a convenient and efficient data container, you may use it to continuously store huge an array of arrays or for matrix computation.
 * @class wMatrix
 * @memberof module:Tools/math/Matrix
 */

let Parent = null;
let Self = function wMatrix( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

// --
// routine
// --

function init( o )
{
  let self = this;

  self._changing = [ 1 ];

  self[ stridesEffectiveSymbol ] = null;
  self[ lengthSymbol ] = null;
  self[ atomsPerElementSymbol ] = null;
  self[ occupiedRangeSymbol ] = null;
  self[ breadthSymbol ] = null;

  self[ stridesSymbol ] = null;
  self[ offsetSymbol ] = null;

  _.workpiece.initFields( self );
  _.assert( arguments.length <= 1 );

  Object.preventExtensions( self );

  self.strides = null;
  self.offset = 0;
  self.breadth = null;

  self._changing[ 0 ] -= 1;

  if( o )
  {

    if( _.mapIs( o ) )
    {

      if( o.atomsPerElement !== undefined )
      {
        _.assert( _.longIs( o.buffer ) );
        if( !o.offset )
        o.offset = 0;
        if( !o.dims )
        {
          if( o.strides )
          o.dims = [ o.atomsPerElement, ( o.buffer.length - o.offset ) / o.strides[ 1 ] ];
          else
          o.dims = [ o.atomsPerElement, ( o.buffer.length - o.offset ) / o.atomsPerElement ];
          o.dims[ 1 ] = Math.floor( o.dims[ 1 ] );
        }
        _.assert( _.intIs( o.dims[ 1 ] ) );
        delete o.atomsPerElement;
      }

    }

    self.copy( o );
  }
  else
  {
    self._sizeChanged();
  }

}

//

function _traverseAct( it )
{
  let self = this;

  if( it.resetting === undefined )
  it.resetting = 1;

  _.Copyable.prototype._traverseAct.pre.call( this, _traverseAct, [ it ] );

  if( !it.dst )
  {
    _.assert( it.technique === 'object' );
    _.assert( it.src instanceof Self );
    it.dst = it.src.clone();
    return it.dst;
  }

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( it.resetting !== undefined );
  _.assert( !!it.dst );

  let dst = it.dst;
  let src = it.src;
  let srcIsInstance = src instanceof Self;
  let dstIsInstance = dst instanceof Self;

  if( src === dst )
  return dst;

  /* */

  if( _.longIs( src ) )
  {
    dst.copyFromBuffer( src );
    return dst;
  }
  else if( _.numberIs( src ) )
  {
    dst.copyFromScalar( src );
    return dst;
  }

  if( dstIsInstance )
  dst._changeBegin();

  if( src.dims )
  {
    _.assert( it.resetting || !dst.dims || _.longIdentical( dst.dims , src.dims ) );
  }

  if( dstIsInstance )
  if( dst._stridesEffective )
  dst[ stridesEffectiveSymbol ] = null;

  /* */

  if( dstIsInstance )
  if( src.buffer !== undefined )
  {
    /* use here resetting option maybe!!!? */

    dst.dims = null;

    if( srcIsInstance && dst.buffer && dst.atomsPerMatrix === src.atomsPerMatrix )
    {
    }
    else if( !srcIsInstance )
    {
      dst.buffer = src.buffer;
      if( src.breadth !== undefined )
      dst.breadth = src.breadth;
      if( src.offset !== undefined )
      dst.offset = src.offset;
      if( src.strides !== undefined )
      dst.strides = src.strides;
    }
    else if( src.buffer && !dst.buffer )
    {
      dst.buffer = self.long.longMakeUndefined( src.buffer , src.atomsPerMatrix );
      dst.offset = 0;
      dst.strides = null;
      dst[ stridesEffectiveSymbol ] = dst.StridesForDimensions( src.dims, !!dst.inputTransposing );
    }
    else if( src.buffer && dst.atomsPerMatrix !== src.atomsPerMatrix )
    {
      dst.buffer = self.long.longMakeUndefined( src.buffer , src.atomsPerMatrix );
      dst.offset = 0;
      dst.strides = null;
      dst[ stridesEffectiveSymbol ] = dst.StridesForDimensions( src.dims, !!dst.inputTransposing );
    }
    else debugger;

  }

  /* */

  if( src.dims )
  dst.dims = src.dims;

  it.copyingAggregates = 0;
  dst = _.Copyable.prototype._traverseAct( it );

  if( srcIsInstance )
  _.assert( _.longIdentical( dst.dims , src.dims ) );

  if( dstIsInstance )
  {
    dst._changeEnd();
    _.assert( dst._changing[ 0 ] === 0 );
  }

  if( srcIsInstance )
  {

    if( dstIsInstance )
    {
      _.assert( dst.hasShape( src ) );
      src.atomEach( function( it )
      {
        dst.atomSet( it.indexNd, it.atom );
      });

    }
    else
    {
      let extract = it.src.extractNormalized();
      let newIteration = it.iterationNew();
      newIteration.select( 'buffer' );
      newIteration.src = extract.buffer;
      dst.buffer = _._cloneAct( newIteration );
      dst.offset = extract.offset;
      dst.strides = extract.strides;
    }
  }

  return dst;
}

_traverseAct.iterationDefaults = Object.create( _._cloner.iterationDefaults ); /* xxx */
_traverseAct.defaults = _.mapSupplementOwn( Object.create( _._cloner.defaults ), _traverseAct.iterationDefaults );

//

function _copy( src, resetting )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  let it = _._cloner( self._traverseAct, { src, dst : self, /*resetting, */ technique : 'object' } );

  self._traverseAct( it );

  return it.dst;
}

//

/**
 * @summary Copy scalars from array `src` into inner matrix.
 * @description Also accepts `src` as scalar, in this case it fills matrix with value of scalar.
 * @param {Array|Number} src Array of scalars or single scalar.
 * @function copy
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function copy( src )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  return self._copy( src, 0 );
}

//

function copyResetting( src )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  return self._copy( src, 1 );
}

//

/**
 * @summary Fills inner matrix with value of scalar `src`.
 * @param {Number} src Scalar.
 * @function copyFromScalar
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function copyFromScalar( src )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.numberIs( src ) );

  self.atomEach( ( it ) => self.atomSet( it.indexNd, src ) );

  return self;
}

//

/**
 * @summary Copy scalars from array `src` into inner matrix.
 * @param {Array} src Array with scarals.
 * @function copyFromScalar
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function copyFromBuffer( src )
{
  let self = this;
  self._bufferAssign( src );
  return self;
}

//

function clone()
{
  let self = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  let dst = _.Copyable.prototype.clone.call( self );

  if( dst.buffer === self.buffer )
  dst[ bufferSymbol ] = _.longSlice( dst.buffer );

  return dst;
}

//

function CopyTo( dst, src )
{

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  if( dst === src )
  return dst;

  let odst = dst;
  let dstDims = Self.DimsOf( dst );
  let srcDims = Self.DimsOf( src );

  _.assert( _.longIdentical( srcDims, dstDims ), '(-src-) and (-dst-) should have same dimensions' );
  _.assert( !_.instanceIs( this ) )

  if( !_.matrixIs( src ) )
  {

    src = this.vectorAdapter.from( src );
    if( _.longIs( dst ) )
    dst = this.vectorAdapter.from( dst );

    if( _.vectorAdapterIs( dst ) )
    for( let s = 0 ; s < src.length ; s += 1 )
    dst.eSet( s, src.eGet( s ) )
    else if( _.matrixIs( dst ) )
    for( let s = 0 ; s < src.length ; s += 1 )
    dst.atomSet( [ s, 0 ], src.eGet( s ) )
    else _.assert( 0, 'unknown type of (-dst-)', _.strType( dst ) );

    return odst;
  }
  else
  {

    let dstDims = Self.DimsOf( dst );
    let srcDims = Self.DimsOf( src );

    if( _.matrixIs( dst ) )
    src.atomEach( function( it )
    {
      dst.atomSet( it.indexNd , it.atom );
    });
    else if( _.vectorAdapterIs( dst ) )
    src.atomEach( function( it )
    {
      dst.eSet( it.indexFlat , it.atom );
    });
    else if( _.longIs( dst ) )
    src.atomEach( function( it )
    {
      dst[ it.indexFlat ] = it.atom;
    });
    else _.assert( 0, 'unknown type of (-dst-)', _.strType( dst ) );

  }

  return odst;
}

//

function extractNormalized()
{
  let self = this;
  let result = Object.create( null );

  _.assert( arguments.length === 0, 'Expects no arguments' );

  result.buffer = self.long.longMakeUndefined( self.buffer , self.atomsPerMatrix );
  result.offset = 0;
  result.strides = self.StridesForDimensions( self.dims, self.inputTransposing );

  self.atomEach( function( it )
  {
    let i = self._FlatAtomIndexFromIndexNd( it.indexNd, result.strides );
    result.buffer[ i ] = it.atom;
  });

  return result;
}

// --
// size in bytes
// --

function _sizeGet()
{
  let result = this.sizeOfAtom*this.atomsPerMatrix;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfElementGet()
{
  let result = this.sizeOfAtom*this.atomsPerElement;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfElementStrideGet()
{
  let result = this.sizeOfAtom*this.strideOfElement;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfColGet()
{
  let result = this.sizeOfAtom*this.atomsPerCol;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfColStrideGet()
{
  let result = this.sizeOfAtom*this.strideOfCol;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfRowGet()
{
  let result = this.sizeOfAtom*this.atomsPerRow;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfRowStrideGet()
{
  let result = this.sizeOfAtom*this.strideOfRow;
  _.assert( result >= 0 );
  return result;
}

//

function _sizeOfAtomGet()
{
  _.assert( !!this.buffer );
  let result = this.buffer.BYTES_PER_ELEMENT;
  _.assert( result >= 0 );
  return result;
}

// --
// size in atoms
// --

function _atomsPerElementGet()
{
  let self = this;
  return self[ atomsPerElementSymbol ];
}

//

function _atomsPerColGet()
{
  let self = this;
  let result = self.dims[ 0 ];
  _.assert( result >= 0 );
  return result;
}

//

function _atomsPerRowGet()
{
  let self = this;
  let result = self.dims[ 1 ];
  _.assert( result >= 0 );
  return result;
}

//

function _nrowGet()
{
  let self = this;
  let result = self.dims[ 0 ];
  _.assert( result >= 0 );
  return result;
}

//

function _ncolGet()
{
  let self = this;
  let result = self.dims[ 1 ];
  _.assert( result >= 0 );
  return result;
}

//

function _atomsPerMatrixGet()
{
  let self = this;
  let result = self.length === Infinity ? self.atomsPerElement : self.length * self.atomsPerElement;
  _.assert( _.numberIsFinite( result ) );
  _.assert( result >= 0 );
  return result;
}

//

/**
 * @summary Returns number of atoms per matrix for provided dimensions array `dims`.
 * @param {Array} dims Dimensions array.
 * @function AtomsPerMatrixForDimensions
 * @memberof module:Tools/math/Matrix.wMatrix
 * @static
 */

function AtomsPerMatrixForDimensions( dims )
{
  let result = 1;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.arrayIs( dims ) );
  _.assert( !_.instanceIs( this ) )

  for( let d = dims.length-1 ; d >= 0 ; d-- )
  {
    _.assert( dims[ d ] >= 0 )
    result *= dims[ d ];
  }

  return result;
}

//

/**
 * @summary Returns number of rows in provided matrix `src`.
 * @param {Object} src Instance of wMatrix.
 * @function NrowOf
 * @memberof module:Tools/math/Matrix.wMatrix
 * @static
 */

function NrowOf( src )
{
  if( src instanceof Self )
  return src.dims[ 0 ];
  _.assert( src.length >= 0 );
  return src.length;
}

//

/**
 * @summary Returns number of columns in provided matrix `src`.
 * @param {Object} src Instance of wMatrix.
 * @function NcolOf
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function NcolOf( src )
{
  if( src instanceof Self )
  return src.dims[ 1 ];
  _.assert( src.length >= 0 );
  return 1;
}

//

/**
 * @summary Returns dimensions array for provided matrix `src`.
 * @param {Object} src Instance of wMatrix.
 * @function DimsOf
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function DimsOf( src )
{
  if( src instanceof Self )
  return src.dims.slice();
  let result = [ 0, 1 ];
  _.assert( src.length >= 0 );
  result[ 0 ] = src.length;
  return result;
}

// --
// stride
// --

function _lengthGet()
{
  return this[ lengthSymbol ];
}

//

function _occupiedRangeGet()
{
  return this[ occupiedRangeSymbol ];
}

//

function _stridesEffectiveGet()
{
  return this[ stridesEffectiveSymbol ];
}

//

function _stridesSet( src )
{
  let self = this;

  // _.assert( _.longIs( src ) || _.numberIs( src ) || src === null );
  _.assert( _.longIs( src ) || src === null );

  if( _.longIs( src ) )
  src = _.longSlice( src );

  self[ stridesSymbol ] = src;

  self._sizeChanged();

}

//

function _strideOfElementGet()
{
  return this._stridesEffective[ this._stridesEffective.length-1 ];
}

//

function _strideOfColGet()
{
  return this._stridesEffective[ 1 ];
}

//

function _strideInColGet()
{
  return this._stridesEffective[ 0 ];
}

//

function _strideOfRowGet()
{
  return this._stridesEffective[ 0 ];
}

//

function _strideInRowGet()
{
  return this._stridesEffective[ 1 ];
}

//

function StridesForDimensions( dims, transposing )
{

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.arrayIs( dims ) );
  _.assert( _.boolLike( transposing ) );
  _.assert( dims[ 0 ] >= 0 );
  _.assert( dims[ dims.length-1 ] >= 0 );

  let strides = dims.slice();

  if( transposing )
  {
    strides.push( 1 );
    strides.splice( 0, 1 );
    _.assert( strides[ 1 ] > 0 );
    _.assert( strides[ strides.length-1 ] > 0 );
    for( let i = strides.length-2 ; i >= 0 ; i-- )
    strides[ i ] = strides[ i ]*strides[ i+1 ];
  }
  else
  {
    strides.splice( strides.length-1, 1 );
    strides.unshift( 1 );
    _.assert( strides[ 0 ] > 0 );
    _.assert( strides[ 1 ] >= 0 );
    for( let i = 1 ; i < strides.length ; i++ )
    strides[ i ] = strides[ i ]*strides[ i-1 ];
  }

  /* */

  if( dims[ 0 ] === Infinity )
  strides[ 0 ] = 0;
  if( dims[ 1 ] === Infinity )
  strides[ 1 ] = 0;

  return strides;
}

//

function StridesRoll( strides )
{

  _.assert( arguments.length === 1, 'Expects single argument' );

  for( let s = strides.length-2 ; s >= 0 ; s-- )
  strides[ s ] = strides[ s+1 ]*strides[ s ];

  return strides;
}

// --
// buffer
// --

function _bufferSet( src )
{
  let self = this;

  if( self[ bufferSymbol ] === src )
  return;

  if( _.numberIs( src ) )
  src = this.long.longMake([ src ]);

  _.assert( _.longIs( src ) || src === null );

  // if( src )
  // debugger;

  self[ bufferSymbol ] = src;

  if( !self._changing[ 0 ] )
  self[ dimsSymbol ] = null;

  self._sizeChanged();
}

//

function _offsetSet( src )
{
  let self = this;

  _.assert( _.numberIs( src ) );

  self[ offsetSymbol ] = src;

  self._sizeChanged();

}

//

function _bufferAssign( src )
{
  let self = this;
  self._changeBegin();

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.longIs( src ) );
  _.assert( self.atomsPerMatrix === src.length, 'matrix', self.dims, 'should have', self.atomsPerMatrix, 'atoms, but got', src.length );

  self.atomEach( function( it )
  {
    self.atomSet( it.indexNd, src[ it.indexFlatRowFirst ] );
  });

  self._changeEnd();
  return self;
}

//

function bufferCopyTo( dst )
{
  let self = this;
  let atomsPerMatrix = self.atomsPerMatrix;

  if( !dst )
  dst = self.long.longMakeUndefined( self.buffer, atomsPerMatrix );

  _.assert( arguments.length === 0 || arguments.length === 1 );
  _.assert( _.longIs( dst ) );
  _.assert( atomsPerMatrix === dst.length, 'matrix', self.dims, 'should have', atomsPerMatrix, 'atoms, but got', dst.length );

  throw _.err( 'not tested' );

  self.atomEach( function( it )
  {
    dst[ it.indexFlat ] = it.atom;
  });

  return dst;
}

// --
// reshape
// --

function _changeBegin()
{
  let self = this;

  self._changing[ 0 ] += 1;

}

//

function _changeEnd()
{
  let self = this;

  self._changing[ 0 ] -= 1;
  self._sizeChanged();

}

//

function _sizeChanged()
{
  let self = this;

  if( self._changing[ 0 ] )
  return;

  self._adjust();

}

//

function _adjust()
{
  let self = this;

  self._adjustVerify();
  self._adjustAct();
  self._adjustValidate();

}

//

function _adjustAct()
{
  let self = this;
  let changed = false;

  self._changing[ 0 ] += 1;

  /* adjust breadth */

  if( _.numberIs( self.breadth ) )
  {
    debugger;
    self.breadth = [ self.breadth ];
    changed = true;
  }

  /* strides */

  if( _.numberIs( self.strides ) )
  {
    debugger;
    let strides = _.dup( 1, self.breadth.length+1 );
    strides[ strides.length-1 ] = self.strides;
    self.strides = self.StridesRoll( strides );
    changed = true;
  }

  self[ stridesEffectiveSymbol ] = null;

  if( self.strides )
  {
    self[ stridesEffectiveSymbol ] = self.strides;
  }

  /* dims */

  _.assert( self.dims === null || _.longIs( self.dims ) );

  if( !self.dims )
  {
    if( self._dimsWas )
    {
      _.assert( _.arrayIs( self._dimsWas ) );
      _.assert( _.arrayIs( self._dimsWas ) );
      _.assert( _.longIs( self.buffer ) );
      _.assert( self.offset >= 0 );

      let dims = self._dimsWas.slice();
      dims[ self.growingDimension ] = 1;
      let ape = _.avector.reduceToProduct( dims );
      let l = ( self.buffer.length - self.offset ) / ape;
      dims[ self.growingDimension ] = l;
      self[ dimsSymbol ] = dims;

      _.assert( l >= 0 );
      _.assert( _.intIs( l ) );

    }
    else if( self.strides )
    {
      _.assert( 0, 'Cant deduce dims from strides' );
    }
    else
    {
      _.assert( _.longIs( self.buffer ), 'Expects buffer' );
      if( self.buffer.length - self.offset > 0 )
      {
        self[ dimsSymbol ] = [ self.buffer.length - self.offset, 1 ];
        if( !self._stridesEffective )
        self[ stridesEffectiveSymbol ] = [ 1, self.buffer.length - self.offset ];
      }
      else
      {
        self[ dimsSymbol ] = [ 1, 0 ];
        if( !self._stridesEffective )
        self[ stridesEffectiveSymbol ] = [ 1, 1 ];
      }
      changed = true;
    }
  }

  _.assert( _.arrayIs( self.dims ) );

  self._dimsWas = self.dims.slice();

  self[ breadthSymbol ] = self.dims.slice( 0, self.dims.length-1 );
  self[ lengthSymbol ] = self.dims[ self.dims.length-1 ];

  /* strides */

  if( !self._stridesEffective )
  {

    _.assert( _.boolLike( self.inputTransposing ) );
    _.assert( self.dims[ 0 ] >= 0 );
    _.assert( self.dims[ self.dims.length-1 ] >= 0 );

    let strides = self[ stridesEffectiveSymbol ] = self.StridesForDimensions( self.dims, self.inputTransposing );

  }

  _.assert( self._stridesEffective.length >= 2 );

  /* atoms per element */

  _.assert( self.breadth.length === 1, 'not tested' );
  self[ atomsPerElementSymbol ] = _.avector.reduceToProduct( self.breadth );

  /* buffer region */

  let dims = self.dims;
  let offset = self.offset;
  let occupiedRange = [ 0, 0 ];
  let last;

  if( self.length !== 0 )
  {

    for( let s = 0 ; s < self._stridesEffective.length ; s++ )
    {
      if( dims[ s ] === Infinity )
      continue;

      last = dims[ s ] > 0 ? self._stridesEffective[ s ]*( dims[ s ]-1 ) : 0;

      _.assert( last >= 0, 'not tested' );

      occupiedRange[ 1 ] += last;

    }

  }

  occupiedRange[ 0 ] += offset;
  occupiedRange[ 1 ] += offset;
  occupiedRange[ 1 ] += 1;

  self[ occupiedRangeSymbol ] = occupiedRange;

  /* done */

  _.entityFreeze( self.dims );
  _.entityFreeze( self.breadth );
  _.entityFreeze( self._stridesEffective );

  self._changing[ 0 ] -= 1;

}

//

function _adjustVerify()
{
  let self = this;

  _.assert( _.longIs( self.buffer ), 'matrix needs buffer' );
  _.assert( _.longIs( self.strides ) || self.strides === null );
  _.assert( _.numberIs( self.offset ), 'matrix needs offset' );

}

//

function _adjustValidate()
{
  let self = this;

  _.assert( _.arrayIs( self.breadth ) );
  _.assert( self.dims.length === self.breadth.length+1 );
  _.assert( _.arrayIs( self.dims ) );
  _.assert( _.arrayIs( self.breadth ) );

  _.assert( self.length >= 0 );
  _.assert( self.atomsPerElement >= 0 );
  _.assert( self.strideOfElement >= 0 );

  _.assert( _.longIs( self.buffer ) );
  _.assert( _.longIs( self.breadth ) );

  _.assert( _.longIs( self._stridesEffective ) );
  _.assert( _.numbersAreInt( self._stridesEffective ) );
  _.assert( _.numbersArePositive( self._stridesEffective ) );
  _.assert( self._stridesEffective.length >= 2 );

  _.assert( _.numbersAreInt( self.dims ) );
  _.assert( _.numbersArePositive( self.dims ) );

  _.assert( _.intIs( self.length ) );
  _.assert( self.length >= 0 );
  _.assert( self.dims[ self.dims.length-1 ] === self.length );

  _.assert( self.breadth.length+1 === self._stridesEffective.length );

  if( Config.debug )
  for( let d = 0 ; d < self.dims.length-1 ; d++ )
  _.assert( self.dims[ d ] >= 0 );

  if( Config.debug )
  if( self.atomsPerMatrix > 0 && _.numberIsFinite( self.length ) )
  for( let d = 0 ; d < self.dims.length ; d++ )
  _.assert( self.offset + ( self.dims[ d ]-1 )*self._stridesEffective[ d ] <= self.buffer.length, 'out of bound' );

}

//

function _breadthGet()
{
  let self = this;
  return self[ breadthSymbol ];
}

//

function _breadthSet( breadth )
{
  let self = this;

  if( _.numberIs( breadth ) )
  breadth = [ breadth ];
  else if( _.bufferTypedIs( breadth ) )
  breadth = _.arrayFrom( breadth );

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( breadth === null || _.arrayIs( breadth ), 'Expects array (-breadth-) but got', _.strType( breadth ) );

  if( breadth === self.breadth )
  return;

  if( breadth !== null && self.breadth !== null )
  if( _.longIdentical( self.breadth, breadth ) )
  return;

  self._changeBegin();

  if( breadth === null )
  {
    debugger;
    if( self[ dimsSymbol ] === null )
    debugger;
    self[ breadthSymbol ] = null
    if( self[ dimsSymbol ] === null )
    self._dimsWas = null;
  }
  else
  {
    let _dimsWas = breadth.slice();
    _dimsWas.push( self._dimsWas ? self._dimsWas[ self._dimsWas.length-1 ] : 0 );
    self[ breadthSymbol ] = _.entityFreeze( breadth.slice() );
    self[ dimsSymbol ] = null;
    self._dimsWas = _dimsWas;
  }

  self._changeEnd();
}

//

function _dimsSet( src )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( src )
  {

    _.assert( _.arrayIs( src ) );
    _.assert( src.length >= 2 );
    _.assert( _.numbersAreInt( src ) );
    _.assert( src[ 0 ] >= 0 );
    _.assert( src[ src.length-1 ] >= 0 );
    self[ dimsSymbol ] = _.entityFreeze( src.slice() );
    self[ breadthSymbol ] = _.entityFreeze( src.slice( 0, src.length-1 ) );

  }
  else
  {
    self[ dimsSymbol ] = null;
    self[ breadthSymbol ] = null;
  }

  _.assert( self[ dimsSymbol ] === null || _.numbersAreInt( self[ dimsSymbol ] ) );

  self._sizeChanged();

  return src;
}

//

/**
 * @summary Expands current matrix to size.
 * @param {Array} expand New dimensions of the matrix.
 * @function expand
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function expand( expand )
{
  let self = this;

  /* */

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( expand.length === self.dims.length );

  /* */

  let dims = self.dims.slice();
  for( let i = 0 ; i < dims.length ; i++ )
  {
    if( !expand[ i ] )
    {
      expand[ i ] = [ 0, 0 ];
    }
    else if( _.numberIs( expand[ i ] ) )
    {
      expand[ i ] = [ expand[ i ], expand[ i ] ];
    }
    else
    {
      expand[ i ][ 0 ] = expand[ i ][ 0 ] || 0;
      expand[ i ][ 1 ] = expand[ i ][ 1 ] || 0;
    }
    _.assert( expand[ i ].length === 2 );
    _.assert( -expand[ i ][ 0 ] <= dims[ i ] );
    _.assert( -expand[ i ][ 1 ] <= dims[ i ] );
    dims[ i ] += expand[ i ][ 0 ] + expand[ i ][ 1 ];
  }

  if( self.hasShape( dims ) )
  return self;

  let atomsPerMatrix = Self.AtomsPerMatrixForDimensions( dims );
  let strides = Self.StridesForDimensions( dims, 0 );
  let buffer = self.long.longMakeZeroed( self.buffer, atomsPerMatrix );

  /* move data */

  self.atomEach( function( it )
  {
    for( let i = 0 ; i < dims.length ; i++ )
    {
      it.indexNd[ i ] += expand[ i ][ 0 ];
      if( it.indexNd[ i ] < 0 || it.indexNd[ i ] >= dims[ i ] )
      return;
    }
    let indexFlat = Self._FlatAtomIndexFromIndexNd( it.indexNd , strides );
    _.assert( indexFlat >= 0 );
    _.assert( indexFlat < buffer.length );
    buffer[ indexFlat ] = it.atom;
  });

  /* copy */

  self.copyResetting
  ({
    inputTransposing : 0,
    offset : 0,
    buffer,
    dims,
    strides : null,
  });

  return self;
}

//

function ShapesAreSame( ins1, ins2 )
{
  _.assert( !_.instanceIs( this ) );

  let dims1 = this.DimsOf( ins1 );
  let dims2 = this.DimsOf( ins2 );

  return _.longIdentical( dims1, dims2 );
}

//

function hasShape( src )
{
  let self = this;

  // src = Self.DimsOf( src );

  if( src instanceof Self )
  src = src.dims;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.arrayIs( src ) );

  return _.longIdentical( self.dims, src );
}

//

function isSquare()
{
  let self = this;
  _.assert( arguments.length === 0, 'Expects no arguments' );
  return self.dims[ 0 ] === self.dims[ 1 ];
}

// --
// etc
// --

function flatAtomIndexFrom( indexNd )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  let result = self._FlatAtomIndexFromIndexNd( indexNd, self._stridesEffective );

  return result + self.offset;
}

//

function _FlatAtomIndexFromIndexNd( indexNd, strides )
{
  let result = 0;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.arrayIs( indexNd ) );
  _.assert( _.arrayIs( strides ) );
  _.assert( indexNd.length === strides.length );

  for( let i = 0 ; i < indexNd.length ; i++ )
  {
    result += indexNd[ i ]*strides[ i ];
  }

  return result;
}

//

function flatGranuleIndexFrom( indexNd )
{
  let self = this;
  let result = 0;
  let stride = 1;
  let d = self._stridesEffective.length-indexNd.length;

  debugger;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( indexNd.length <= self._stridesEffective.length );

  let f = self._stridesEffective.length - indexNd.length;
  // for( let i = indexNd.length-1 ; i >= 0 ; i-- )
  for( let i = f ; i < indexNd.length ; i++ )
  {
    stride = self._stridesEffective[ i ];
    result += indexNd[ i-f ]*stride;
  }

  return result;
}

//

function transpose()
{
  let self = this;
  self._changeBegin();

  let dims = self.dims.slice();
  let strides = self._stridesEffective.slice();

  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( dims.length >= 2 );
  _.assert( strides.length >= 2 );
  _.assert( strides.length === dims.length );

  // _.longSwapElements( dims, dims.length-1, dims.length-2 );
  // _.longSwapElements( strides, strides.length-1, strides.length-2 );

  _.longSwapElements( dims, 0, 1 );
  _.longSwapElements( strides, 0, 1 );

  self.strides = strides;
  self.dims = dims;

  self._changeEnd();
  return self;
}

//

function _equalAre( it )
{

  _.assert( arguments.length === 1, 'Expects exactly three arguments' );
  _.assert( _.routineIs( it.onNumbersAreEqual ) );
  _.assert( _.lookIterationIs( it ) );

  it.continue = false;

  if( !( it.src2 instanceof Self ) )
  {
    it.result = false;
    debugger;
    return it.result;
  }

  if( it.src.length !== it.src2.length )
  {
    it.result = false;
    debugger;
    return it.result;
  }

  if( it.src.buffer.constructor !== it.src2.buffer.constructor )
  {
    it.result = false;
    debugger;
    return it.result;
  }

  if( !_.longIdentical( it.src.breadth, it.src2.breadth )  )
  {
    it.result = false;
    debugger;
    return it.result;
  }

  it.result = it.src.atomWhile( function( atom, indexNd, indexFlat )
  {
    let atom2 = it.src2.atomGet( indexNd );
    return it.onNumbersAreEqual( atom, atom2 );
  });

  _.assert( _.boolIs( it.result ) );
  return it.result;
}

_.routineExtend( _equalAre, _._equal );

//

/**
 * @summary Checks if provided argument is a instance of wMatrix.
 * @param {} src Entity to check.
 * @function is
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function Is( src )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  return _.matrixIs( src );
}

//

/**
 * @summary Converts current matrix to string.
 * @description Returns formatted string that represents maxtrix of scalars.
 * @param {Object} o Options map.
 * @param {String} o.tab='' String inserted before each new line
 * @param {Number} o.precision=3 Precision of scalar values
 * @param {Boolean} o.usingSign=1 Prepend sign to scalar values
 * @function toStr
 * @memberof module:Tools/math/Matrix.wMatrix#
 */

function toStr( o )
{
  let self = this;
  let result = '';

  o = o || Object.create( null );
  _.routineOptions( toStr, o );

  let l = self.dims[ 0 ];
  let atomsPerRow, atomsPerCol;
  let col, row;
  let m, c, r, e;

  let isInt = true;
  self.atomEach( function( it )
  {
    isInt = isInt && _.intIs( it.atom );
  });

  /* */

  function eToStr()
  {
    let e = row.eGet( c );

    if( isInt )
    {
      if( !o.usingSign || e < 0 )
      result += e.toFixed( 0 );
      else
      result += '+' + e.toFixed( 0 );
    }
    else
    {
      result += e.toFixed( o.precision );
    }

    result += ', ';

  }

  /* */

  function rowToStr()
  {

    if( m === undefined )
    row = self.rowVectorGet( r );
    else
    row = self.rowVectorOfMatrixGet( [ m ], r );

    if( atomsPerRow === Infinity )
    {
      e = 0;
      eToStr();
      result += '*Infinity';
    }
    else for( c = 0 ; c < atomsPerRow ; c += 1 )
    eToStr();

  }

  /* */

  function matrixToStr( m )
  {

    atomsPerRow = self.atomsPerRow;
    atomsPerCol = self.atomsPerCol;

    if( atomsPerCol === Infinity )
    {
      r = 0;
      rowToStr( 0 );
      result += ' **Infinity';
    }
    else for( r = 0 ; r < atomsPerCol ; r += 1 )
    {
      rowToStr( r );
      if( r < atomsPerCol - 1 )
      result += '\n' + o.tab;
    }

  }

  /* */

  if( self.dims.length === 2 )
  {

    matrixToStr();

  }
  else if( self.dims.length === 3 )
  {

    for( m = 0 ; m < l ; m += 1 )
    {
      result += 'Slice ' + m + ' :\n';
      matrixToStr( m );
    }

  }
  else _.assert( 0, 'not implemented' );

  return result;
}

toStr.defaults =
{
  tab : '',
  precision : 3,
  usingSign : 1,
}

toStr.defaults.__proto__ = _.toStr.defaults;

//

function bufferNormalize()
{
  let self = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  let buffer = self.long.longMakeUndefined( self.buffer, self.atomsPerMatrix );

  let i = 0;
  self.atomEach( function( it )
  {
    buffer[ i ] = it.atom;
    i += 1;
  });

  self.copy
  ({
    buffer,
    offset : 0,
    inputTransposing : 0,
  });

}

//

function submatrix( submatrix )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.arrayIs( submatrix ), 'Expects array (-submatrix-)' );
  _.assert( submatrix.length <= self.dims.length, 'Expects array (-submatrix-) of length of self.dims' );

  for( let s = submatrix.length ; s < self.dims.length ; s++ )
  submatrix.unshift( _.all );

  let dims = [];
  let strides = [];
  let stride = 1;
  let offset = Infinity;

  for( let s = 0 ; s < submatrix.length ; s++ )
  {
    if( submatrix[ s ] === _.all )
    {
      dims[ s ] = self.dims[ s ];
      strides[ s ] = self._stridesEffective[ s ];
    }
    else if( _.numberIs( submatrix[ s ] ) )
    {
      dims[ s ] = 1;
      strides[ s ] = self._stridesEffective[ s ];
      offset = Math.min( self._stridesEffective[ s ]*submatrix[ s ], offset );
    }
    else if( _.arrayIs( submatrix[ s ] ) )
    {
      _.assert( _.arrayIs( submatrix[ s ] ) && submatrix[ s ].length === 2 );
      dims[ s ] = submatrix[ s ][ 1 ] - submatrix[ s ][ 0 ];
      strides[ s ] = self._stridesEffective[ s ];
      offset = Math.min( self._stridesEffective[ s ]*submatrix[ s ][ 0 ], offset );
    }
    else _.assert( 0, 'unknown submatrix request' );
  }

  if( offset === Infinity )
  offset = 0;
  offset += self.offset;

  let result = new Self
  ({
    buffer : self.buffer,
    offset,
    strides,
    dims,
    inputTransposing : self.inputTransposing,
  });

  return result;
}

// --
// iterator
// --

function atomWhile( o )
{
  let self = this;
  let result = true;

  if( _.routineIs( o ) )
  o = { onAtom : o }

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( atomWhile, o );
  _.assert( _.routineIs( o.onAtom ) );

  let dims = self.dims;

  function handleEach( indexNd, indexFlat )
  {
    let value = self.atomGet( indexNd );
    result = o.onAtom.call( self, value, indexNd, indexFlat, o );
    return result;
  }

  _.eachInMultiRange
  ({
    ranges : dims,
    onEach : handleEach,
  })

  return result;
}

atomWhile.defaults =
{
  onAtom : null,
}

//

function atomEach( onAtom, args )
{
  let self = this;
  let dims = self.dims;

  if( args === undefined )
  args = [];

  _.assert( arguments.length <= 2 );
  _.assert( self.dims.length === 2, 'not tested' );
  _.assert( _.arrayIs( args ) );
  _.assert( onAtom.length === 1 );

  args.unshift( null );
  args.unshift( null );

  let dims0 = dims[ 0 ];
  let dims1 = dims[ 1 ];

  if( dims1 === Infinity )
  dims1 = 1;

  let it = Object.create( null );
  it.args = args;
  let indexFlat = 0;
  for( let c = 0 ; c < dims1 ; c++ )
  for( let r = 0 ; r < dims0 ; r++ )
  {
    it.indexNd = [ r, c ];
    it.indexFlat = indexFlat;
    it.indexFlatRowFirst = r*dims[ 1 ] + c;
    it.atom = self.atomGet( it.indexNd );
    onAtom.call( self, it );
    indexFlat += 1;
  }

  return self;
}

// --
// components accessor
// --

function atomFlatGet( index )
{
  let i = this.offset+index;
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.numberIs( index ) );
  _.assert( i < this.buffer.length );
  _.assert( this.occupiedRange[ 0 ] <= i && i < this.occupiedRange[ 1 ] );
  let result = this.buffer[ i ];
  return result;
}

//

function atomFlatSet( index, value )
{
  let i = this.offset+index;
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.numberIs( index ) );
  _.assert( i < this.buffer.length );
  _.assert( this.occupiedRange[ 0 ] <= i && i < this.occupiedRange[ 1 ] );
  this.buffer[ i ] = value;
  return this;
}

//

function atomGet( index )
{
  let i = this.flatAtomIndexFrom( index );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( i < this.buffer.length );
  _.assert( this.occupiedRange[ 0 ] <= i && i < this.occupiedRange[ 1 ] );
  _.assert( index[ 0 ] < this.dims[ 0 ] );
  _.assert( index[ 1 ] < this.dims[ 1 ] );
  let result = this.buffer[ i ];
  return result;
}

//

function atomSet( index, value )
{
  let i = this.flatAtomIndexFrom( index );
  _.assert( _.numberIs( value ) );
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( i < this.buffer.length );
  _.assert( this.occupiedRange[ 0 ] <= i && i < this.occupiedRange[ 1 ] );
  _.assert( index[ 0 ] < this.dims[ 0 ] );
  _.assert( index[ 1 ] < this.dims[ 1 ] );
  this.buffer[ i ] = value;
  return this;
}

//

function atomsGet( range )
{
  let self = this;

  _.assert( _.longIs( range ) );
  _.assert( range.length === 2 );
  _.assert( self.breadth.length === 1 );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( range[ 1 ] >= range[ 0 ] );

  debugger;

  let result = self.vectorAdapter.fromLongLrange
  (
    self.buffer,
    self.offset+range[ 0 ],
    ( range[ 1 ]-range[ 0 ] )
  );

  debugger;

  return result;
}

//

function asVector()
{
  let self = this
  let result = null;

  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( self.strideOfElement === self.atomsPerElement );
  _.assert( self.strideOfElement === self.atomsPerElement, 'elementsInRangeGet :', 'cant make single row for elements with extra stride' );

  result = self.vectorAdapter.fromLongLrange
  (
    self.buffer,
    self.occupiedRange[ 0 ],
    self.occupiedRange[ 1 ]-self.occupiedRange[ 0 ]
  );

  return result;
}

//

function granuleGet( index )
{
  let self = this;
  let atomsPerGranule;

  debugger;
  _.assert( 0, 'not imlemented' );

  if( index.length < self._stridesEffective.length+1 )
  atomsPerGranule = _.avector.reduceToProduct( self._stridesEffective.slice( index.length-1 ) );
  else
  atomsPerGranule = 1;

  let result = self.vectorAdapter.fromLongLrange
  (
    this.buffer,
    this.offset + this.flatGranuleIndexFrom( index ),
    atomsPerGranule
  );

  return result;
}

//

function elementSlice( index )
{
  let self = this;
  let result = self.eGet( index );
  return self.vectorAdapter.slice( result );
}

//

function elementsInRangeGet( range )
{
  let self = this
  let result;

  _.assert( _.longIs( range ) );
  _.assert( range.length === 2 );
  _.assert( self.breadth.length === 1 );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( range[ 1 ] >= range[ 0 ] );
  _.assert( self.strideOfElement === self.atomsPerElement, 'elementsInRangeGet :', 'cant make single row for elements with extra stride' );

  result = self.vectorAdapter.fromLongLrange
  (
    self.buffer,
    self.offset+self.strideOfElement*range[ 0 ],
    self.atomsPerElement*( range[ 1 ]-range[ 0 ] )
  );

  return result;
}

//

function eGet( index )
{

  _.assert( this.dims.length === 2, 'not implemented' );
  _.assert( 0 <= index && index < this.dims[ this.dims.length-1 ], 'out of bound' );
  _.assert( _.numberIs( index ) );
  _.assert( arguments.length === 1, 'Expects single argument' );

  let result = this.vectorAdapter.fromLongLrangeAndStride
  (
    this.buffer,
    this.offset + index*this._stridesEffective[ this._stridesEffective.length-1 ],
    this.dims[ this.dims.length-2 ],
    this._stridesEffective[ this._stridesEffective.length-2 ]
  );

  return result;
}

//

function eSet( index, srcElement )
{
  let self = this;
  let selfElement = self.eGet( index );

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  self.vectorAdapter.assign( selfElement, srcElement );

  return self;
}

//

function elementsSwap( i1, i2 )
{
  let self = this;

  _.assert( 0 <= i1 && i1 < self.length );
  _.assert( 0 <= i2 && i2 < self.length );
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  if( i1 === i2 )
  return self;

  let v1 = self.eGet( i1 );
  let v2 = self.eGet( i2 );

  self.vectorAdapter.swapVectors( v1, v2 );

  return self;
}

//

function lineVectorGet( d, index )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( self.dims.length === 2 );

  if( d === 0 )
  return self.colVectorGet( index );
  else if( d === 1 )
  return self.rowVectorGet( index );
  else
  _.assert( 0, 'unknown dimension' );

}

//

function lineSet( d, index, src )
{
  let self = this;

  _.assert( arguments.length === 3, 'Expects exactly three arguments' );
  _.assert( self.dims.length === 2 );

  if( d === 0 )
  return self.colSet( index, src );
  else if( d === 1 )
  return self.rowSet( index, src );
  else
  _.assert( 0, 'unknown dimension' );

}

//

function linesSwap( d, i1, i2 )
{
  let self = this;

  let ad = d+1;
  if( ad > 1 )
  ad = 0;

  _.assert( arguments.length === 3, 'Expects exactly three arguments' );
  _.assert( self.dims.length === 2 );
  _.assert( 0 <= i1 && i1 < self.dims[ d ] );
  _.assert( 0 <= i2 && i2 < self.dims[ d ] );

  if( i1 === i2 )
  return self;

  let v1 = self.lineVectorGet( ad, i1 );
  let v2 = self.lineVectorGet( ad, i2 );

  self.vectorAdapter.swapVectors( v1, v2 );

  return self;
}

//

function rowVectorOfMatrixGet( matrixIndex, rowIndex )
{

  debugger;
  throw _.err( 'not tested' );
  _.assert( index < this.dims[ 1 ] );

  let matrixOffset = this.flatGranuleIndexFrom( matrixIndex );
  let result = this.vectorAdapter.fromLongLrangeAndStride
  (
    this.buffer,
    this.offset + rowIndex*this.strideOfRow + matrixOffset,
    this.atomsPerRow,
    this.strideInRow
  );

  return result;
}

//

function rowVectorGet( index )
{

  _.assert( this.dims.length === 2, 'not implemented' );
  _.assert( 0 <= index && index < this.dims[ 0 ], 'out of bound' );
  _.assert( _.numberIs( index ) );
  _.assert( arguments.length === 1, 'Expects single argument' );

  let result = this.vectorAdapter.fromLongLrangeAndStride
  (
    this.buffer,
    this.offset + index*this.strideOfRow,
    this.atomsPerRow,
    this.strideInRow
  );

  return result;
}

//

function rowSet( rowIndex, srcRow )
{
  let self = this;
  let selfRow = self.rowVectorGet( rowIndex );

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  self.vectorAdapter.assign( selfRow, srcRow );

  return self;
}

//

function rowsSwap( i1, i2 )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  return self.linesSwap( 0, i1, i2 );
}

//

function colVectorGet( index )
{

  _.assert( this.dims.length === 2, 'not implemented' );
  _.assert( 0 <= index && index < this.dims[ 1 ], 'out of bound' );
  _.assert( _.numberIs( index ) );
  _.assert( arguments.length === 1, 'Expects single argument' );

  let result = this.vectorAdapter.fromLongLrangeAndStride
  (
    this.buffer,
    this.offset + index*this.strideOfCol,
    this.atomsPerCol,
    this.strideInCol
  );

  return result;
}

//

function colSet( index, srcCol )
{
  let self = this;
  let selfCol = self.colVectorGet( index );

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  self.vectorAdapter.assign( selfCol, srcCol );

  return self;
}

//

function colsSwap( i1, i2 )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  return self.linesSwap( 1, i1, i2 );
}

//

function _pivotDimension( d, current, expected )
{
  let self = this;

  for( let p1 = 0 ; p1 < expected.length ; p1++ )
  {
    if( expected[ p1 ] === current[ p1 ] )
    continue;
    let p2 = current[ expected[ p1 ] ];
    _.longSwapElements( current, p2, p1 );
    self.linesSwap( d, p2, p1 );
  }

  _.assert( expected.length === self.dims[ d ] );
  _.assert( _.longIdentical( current, expected ) );

}

//

function pivotForward( pivots )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( pivots.length === self.dims.length );

  for( let d = 0 ; d < pivots.length ; d++ )
  {
    let current = _.longFromRange([ 0, self.dims[ d ] ]);
    let expected = pivots[ d ];
    if( expected === null )
    continue;
    self._pivotDimension( d, current, expected )
  }

  return self;
}

//

function pivotBackward( pivots )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( pivots.length === self.dims.length );

  for( let d = 0 ; d < pivots.length ; d++ )
  {
    let current = pivots[ d ];
    let expected = _.longFromRange([ 0, self.dims[ d ] ]);
    if( current === null )
    continue;
    current = current.slice();
    self._pivotDimension( d, current, expected )
  }

  return self;
}

//

function _vectorPivotDimension( v, current, expected )
{
  let self = this;

  for( let p1 = 0 ; p1 < expected.length ; p1++ )
  {
    if( expected[ p1 ] === current[ p1 ] )
    continue;
    let p2 = current[ expected[ p1 ] ];
    _.longSwapElements( current, p1, p2 );
    self.vectorAdapter.swapAtoms( v, p1, p2 );
  }

  _.assert( expected.length === v.length );
  _.assert( _.longIdentical( current, expected ) );

}

//

function VectorPivotForward( vector, pivot )
{
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.arrayIs( pivot ) );

  if( _.matrixIs( vector ) )
  return vector.pivotForward([ pivot, null ]);

  let original = vector;
  vector = this.vectorAdapter.from( vector );
  let current = _.longFromRange([ 0, vector.length ]);
  let expected = pivot;
  if( expected === null )
  return vector;
  this._vectorPivotDimension( vector, current, expected )

  return original;
}

//

function VectorPivotBackward( vector, pivot )
{
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.arrayIs( pivot ) );

  if( _.matrixIs( vector ) )
  return vector.pivotBackward([ pivot, null ]);

  let original = vector;
  vector = this.vectorAdapter.from( vector );
  let current = pivot.slice();
  let expected = _.longFromRange([ 0, vector.length ]);
  if( current === null )
  return vector;
  this._vectorPivotDimension( vector, current, expected )

  return original;
}

//

function _longGet()
{
  let self = this;
  if( _.routineIs( self ) )
  self = self.prototype;
  let result = self.vectorAdapter.long;
  _.assert( _.objectIs( result ) );
  return result;
}

// --
// relations
// --

let offsetSymbol = Symbol.for( 'offset' );
let bufferSymbol = Symbol.for( 'buffer' );
let breadthSymbol = Symbol.for( 'breadth' );
let dimsSymbol = Symbol.for( 'dims' );

let stridesSymbol = Symbol.for( 'strides' );
let lengthSymbol = Symbol.for( 'length' );
let stridesEffectiveSymbol = Symbol.for( '_stridesEffective' );

let atomsPerElementSymbol = Symbol.for( 'atomsPerElement' );
let occupiedRangeSymbol = Symbol.for( 'occupiedRange' );

//

let Composes =
{

  dims : null,
  growingDimension : 1,
  inputTransposing : null,

}

//

let Aggregates =
{
  buffer : null,
}

//

let Associates =
{
}

//

let Restricts =
{

  _dimsWas : null,
  _changing : [ 1 ],

}

//

let Medials =
{

  // buffer : null,
  strides : null,
  offset : 0,
  breadth : null,

}

//

let Statics =
{

  /* */

  CopyTo,

  AtomsPerMatrixForDimensions,
  NrowOf,
  NcolOf,
  DimsOf,
  ShapesAreSame,

  StridesForDimensions,
  StridesRoll,

  _FlatAtomIndexFromIndexNd,

  Is,

  /* pivot */

  _vectorPivotDimension,
  VectorPivotForward,
  VectorPivotBackward,

  /* var */

  // accuracy,
  // accuracySqr,
  vectorAdapter : _.vectorAdapter,

}

//

let Forbids =
{

  stride : 'stride',

  strideInBytes : 'strideInBytes',
  strideInAtoms : 'strideInAtoms',

  stridePerElement : 'stridePerElement',
  lengthInStrides : 'lengthInStrides',

  dimensions : 'dimensions',
  dimensionsWithLength : 'dimensionsWithLength',
  stridesEffective : 'stridesEffective',

  colLength : 'colLength',
  rowLength : 'rowLength',

  _generator : '_generator',
  usingOptimizedAccessors : 'usingOptimizedAccessors',
  dimensionsDesired : 'dimensionsDesired',
  array : 'array',

}

//

let ReadOnlyAccessors =
{

  /* size in bytes */

  size : 'size',
  sizeOfElement : 'sizeOfElement',
  sizeOfElementStride : 'sizeOfElementStride',
  sizeOfCol : 'sizeOfCol',
  sizeOfColStride : 'sizeOfColStride',
  sizeOfRow : 'sizeOfRow',
  sizeOfRowStride : 'sizeOfRowStride',
  sizeOfAtom : 'sizeOfAtom',

  /* size in atoms */

  atomsPerElement : 'atomsPerElement', /*  cached*/
  atomsPerCol : 'atomsPerCol',
  atomsPerRow : 'atomsPerRow',
  ncol : 'ncol',
  nrow : 'nrow',
  atomsPerMatrix : 'atomsPerMatrix',

  /* length */

  length : 'length', /* cached */
  occupiedRange : 'occupiedRange', /* cached */
  _stridesEffective : '_stridesEffective', /* cached */

  strideOfElement : 'strideOfElement',
  strideOfCol : 'strideOfCol',
  strideInCol : 'strideInCol',
  strideOfRow : 'strideOfRow',
  strideInRow : 'strideInRow',

}

//

let Accessors =
{

  buffer : 'buffer',
  offset : 'offset',

  strides : 'strides',
  dims : 'dims',
  breadth : 'breadth',

}

// --
// declare
// --

let Extension =
{

  init,

  _traverseAct,
  _copy,
  copy,
  copyResetting,

  copyFromScalar,
  copyFromBuffer,
  clone,

  CopyTo,

  extractNormalized,

  /* size in bytes */

  _sizeGet,

  _sizeOfElementGet,
  _sizeOfElementStrideGet,

  _sizeOfColGet,
  _sizeOfColStrideGet,

  _sizeOfRowGet,
  _sizeOfRowStrideGet,

  _sizeOfAtomGet,

  /* size in atoms */

  _atomsPerElementGet, /* cached */
  _atomsPerColGet,
  _atomsPerRowGet,
  _nrowGet,
  _ncolGet,
  _atomsPerMatrixGet,

  AtomsPerMatrixForDimensions,
  NrowOf,
  NcolOf,

  /* stride */

  _lengthGet, /* cached */
  _occupiedRangeGet, /* cached */

  _stridesEffectiveGet, /* cached */
  _stridesSet, /* cached */

  _strideOfElementGet,
  _strideOfColGet,
  _strideInColGet,
  _strideOfRowGet,
  _strideInRowGet,

  StridesForDimensions,
  StridesRoll,

  /* buffer */

  _bufferSet, /* cached */
  _offsetSet, /* cached */

  _bufferAssign,
  bufferCopyTo,

  /* reshape */

  _changeBegin,
  _changeEnd,

  _sizeChanged,

  _adjust,
  _adjustAct,
  _adjustVerify,
  _adjustValidate,

  _breadthGet, /* cached */
  _breadthSet,
  _dimsSet, /* cached */

  expand,

  ShapesAreSame,
  hasShape,
  isSquare,

  /* etc */

  flatAtomIndexFrom,
  _FlatAtomIndexFromIndexNd,
  flatGranuleIndexFrom,

  transpose,

  _equalAre,
  // equalWith,

  Is,
  toStr,

  bufferNormalize,
  submatrix,

  /* iterator */

  atomWhile,
  atomEach,

  /*

  iterators :

  - map
  - filter
  - reduce
  - zip

  */

  /* components accessor */

  atomFlatGet,
  atomFlatSet,
  atomGet,
  atomSet,
  atomsGet,
  asVector,

  granuleGet,
  elementSlice,
  elementsInRangeGet,
  eGet,
  eSet,
  elementsSwap,

  lineVectorGet,
  lineSet,
  linesSwap,

  rowVectorOfMatrixGet,
  rowVectorGet,
  rowSet,
  rowsSwap,

  colVectorGet,
  colSet,
  colsSwap,

  _pivotDimension,
  pivotForward,
  pivotBackward,

  _vectorPivotDimension,
  VectorPivotForward,
  VectorPivotBackward,

  /* relations */

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Medials,
  Statics,
  Forbids,
  Accessors,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extension,
});

_.Copyable.mixin( Self );

Object.defineProperty( Self, 'accuracy', {
  get : function() { return this.vectorAdapter.accuracy },
});

Object.defineProperty( Self, 'accuracySqr', {
  get : function() { return this.vectorAdapter.accuracySqr },
});

Object.defineProperty( Self.prototype, 'accuracy', {
  get : function() { return this.vectorAdapter.accuracy },
});

Object.defineProperty( Self.prototype, 'accuracySqr', {
  get : function() { return this.vectorAdapter.accuracySqr },
});

_.Matrix = Self;

//

_.assert( !!_.vectorAdapter );
_.assert( !!_.vectorAdapter.long );

_.assert( _.objectIs( _.withDefaultLong ) );
_.assert( _.objectIs( _.withDefaultLong.Fx ) );

_.accessor.readOnly( Self.prototype, ReadOnlyAccessors );
_.accessor.readOnly( Self, { long : { getter : _longGet, setter : false } } );
_.accessor.readOnly( Self.prototype, { long : { getter : _longGet, setter : false } } );

_.assert( Self.prototype.vectorAdapter.long === Self.vectorAdapter.long );
_.assert( Self.long === Self.vectorAdapter.long );
_.assert( Self.prototype.long === Self.vectorAdapter.long );
_.assert( Self.long === _.vectorAdapter.long );

//

// _.mapExtendConditional( _.field.mapper.srcOwnPrimitive, Self, Composes ); /*  qqq : required ??? */
// _.Matrix = _.Matrix = Self;

})();

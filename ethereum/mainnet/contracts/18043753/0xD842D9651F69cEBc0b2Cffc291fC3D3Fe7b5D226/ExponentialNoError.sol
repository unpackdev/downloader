//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// @title Exponential module for storing fixed-precision decimals
// @author Compound
// @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
//        Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
//        `Exp({mantissa: 5100000000000000000})`.
contract ExponentialNoError {
  uint256 public constant EXP_SCALE = 1e18;
  uint256 public constant DOUBLE_SCALE = 1e36;
  uint256 public constant HALF_EXP_SCALE = EXP_SCALE / 2;
  uint256 public constant MANTISSA_ONE = EXP_SCALE;
  uint256 public constant UINT192_MAX = type(uint192).max;
  uint256 public constant UINT128_MAX = type(uint128).max;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  // @dev Truncates the given exp to a whole number value.
  //      For example, truncate(Exp{mantissa: 15 * EXP_SCALE}) = 15
  function _truncate(Exp memory _exp) internal pure returns (uint256 _result) {
    return _exp.mantissa / EXP_SCALE;
  }

  function _truncate(uint256 _u) internal pure returns (uint256 _result) {
    return _u / EXP_SCALE;
  }

  function _safeu192(uint256 _u) internal pure returns (uint192 _result) {
    require(_u < UINT192_MAX, 'overflow');
    return uint192(_u);
  }

  function _safeu128(uint256 _u) internal pure returns (uint128 _result) {
    require(_u < UINT128_MAX, 'overflow');
    return uint128(_u);
  }

  // @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
  function _mulScalarTruncate(Exp memory _a, uint256 _scalar) internal pure returns (uint256 _result) {
    Exp memory _product = _mul(_a, _scalar);
    return _truncate(_product);
  }

  // @dev Multiply an Exp by a scalar, truncate, then _add an to an unsigned integer, returning an unsigned integer.
  function _mulScalarTruncateAddUInt(
    Exp memory _a,
    uint256 _scalar,
    uint256 _addend
  ) internal pure returns (uint256 _result) {
    Exp memory _product = _mul(_a, _scalar);
    return _add(_truncate(_product), _addend);
  }

  // @dev Checks if first Exp is less than second Exp.
  function _lessThanExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa < _right.mantissa;
  }

  // @dev Checks if left Exp <= right Exp.
  function _lessThanOrEqualExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa <= _right.mantissa;
  }

  // @dev Checks if left Exp > right Exp.
  function _greaterThanExp(Exp memory _left, Exp memory _right) internal pure returns (bool _result) {
    return _left.mantissa > _right.mantissa;
  }

  // @dev returns true if Exp is exactly zero
  function _isZeroExp(Exp memory _value) internal pure returns (bool _result) {
    return _value.mantissa == 0;
  }

  function _safe224(uint256 _n, string memory _errorMessage) internal pure returns (uint224 _result) {
    require(_n < 2 ** 224, _errorMessage);
    return uint224(_n);
  }

  function _safe32(uint256 _n, string memory _errorMessage) internal pure returns (uint32 _result) {
    require(_n < 2 ** 32, _errorMessage);
    return uint32(_n);
  }

  function _add(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _add(_a.mantissa, _b.mantissa)});
  }

  function _add(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _add(_a.mantissa, _b.mantissa)});
  }

  function _add(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _add(_a, _b, 'addition overflow');
  }

  function _add(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    uint256 _c = _a + _b;
    require(_c >= _a, _errorMessage);
    return _c;
  }

  function _sub(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _sub(_a.mantissa, _b.mantissa)});
  }

  function _sub(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _sub(_a.mantissa, _b.mantissa)});
  }

  function _sub(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _sub(_a, _b, 'subtraction underflow');
  }

  function _sub(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    require(_b <= _a, _errorMessage);
    return _a - _b;
  }

  function _mul(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _mul(_a.mantissa, _b.mantissa) / EXP_SCALE});
  }

  function _mul(Exp memory _a, uint256 _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _mul(_a.mantissa, _b)});
  }

  function _mul(uint256 _a, Exp memory _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b.mantissa) / EXP_SCALE;
  }

  function _mul(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _mul(_a.mantissa, _b.mantissa) / DOUBLE_SCALE});
  }

  function _mul(Double memory _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _mul(_a.mantissa, _b)});
  }

  function _mul(uint256 _a, Double memory _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b.mantissa) / DOUBLE_SCALE;
  }

  function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _mul(_a, _b, 'multiplication overflow');
  }

  function _mul(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    if (_a == 0 || _b == 0) return 0;
    uint256 _c = _a * _b;
    require(_c / _a == _b, _errorMessage);
    return _c;
  }

  function _div(Exp memory _a, Exp memory _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _div(_mul(_a.mantissa, EXP_SCALE), _b.mantissa)});
  }

  function _div(Exp memory _a, uint256 _b) internal pure returns (Exp memory _result) {
    return Exp({mantissa: _div(_a.mantissa, _b)});
  }

  function _div(uint256 _a, Exp memory _b) internal pure returns (uint256 _result) {
    return _div(_mul(_a, EXP_SCALE), _b.mantissa);
  }

  function _div(Double memory _a, Double memory _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_mul(_a.mantissa, DOUBLE_SCALE), _b.mantissa)});
  }

  function _div(Double memory _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_a.mantissa, _b)});
  }

  function _div(uint256 _a, Double memory _b) internal pure returns (uint256 _result) {
    return _div(_mul(_a, DOUBLE_SCALE), _b.mantissa);
  }

  function _div(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
    return _div(_a, _b, 'divide by zero');
  }

  function _div(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256 _result) {
    require(_b > 0, _errorMessage);
    return _a / _b;
  }

  function _fraction(uint256 _a, uint256 _b) internal pure returns (Double memory _result) {
    return Double({mantissa: _div(_mul(_a, DOUBLE_SCALE), _b)});
  }
}

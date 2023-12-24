// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICurveSlave.sol";

/// @title Piecewise linear curve f(x)
/// @notice returns values for input values 0 to 1e18,
/// described by variables R0, R1, and R2, along with S1 and S2
/// graph of function appears below code
// solhint-disable-next-line contract-name-camelcase
contract ThreeLines0_100 is ICurveSlave {
  /// @notice Thrown when the curve is invalid
  error ThreeLines0_100_InvalidCurve();

  /// @notice Thrown when the breakpoint values are invalid
  error ThreeLines0_100_InvalidBreakpointValues();

  /// @notice Thrown when the input value is too small
  error ThreeLines0_100_InputTooSmall();

  int256 public immutable R0;
  int256 public immutable R1;
  int256 public immutable R2;
  int256 public immutable S1;
  int256 public immutable S2;

  /// @notice curve is constructed on deploy and may not be modified
  /// @param _r0 y value at x=0
  /// @param _r1 y value at the x=S1
  /// @param _r2 y value at x >= S2 && x < 1e18
  /// @param _s1 x value of first breakpoint
  /// @param _s2 x value of second breakpoint
  constructor(int256 _r0, int256 _r1, int256 _r2, int256 _s1, int256 _s2) {
    if (!((0 < _r2) && (_r2 < _r1) && (_r1 < _r0))) revert ThreeLines0_100_InvalidCurve();
    if (!((0 < _s1) && (_s1 < _s2) && (_s2 < 1e18))) revert ThreeLines0_100_InvalidBreakpointValues();

    R0 = _r0;
    R1 = _r1;
    R2 = _r2;
    S1 = _s1;
    S2 = _s2;
  }

  /// @notice calculates f(x)
  /// @param _xValue x value to evaluate
  /// @return _value value of f(x)
  function valueAt(int256 _xValue) external view override returns (int256 _value) {
    // the x value must be between 0 (0%) and 1e18 (100%)
    if (_xValue < 0) revert ThreeLines0_100_InputTooSmall();

    if (_xValue > 1e18) _xValue = 1e18;

    // first piece of the piece wise function
    if (_xValue < S1) {
      int256 _rise = R1 - R0;
      int256 _run = S1;
      return _linearInterpolation(_rise, _run, _xValue, R0);
    }
    // second piece of the piece wise function
    if (_xValue < S2) {
      int256 _rise = R2 - R1;
      int256 _run = S2 - S1;
      return _linearInterpolation(_rise, _run, _xValue - S1, R1);
    }
    // the third and final piece of piecewise function, simply a line
    // since we already know that _xValue <= 1e18, this is safe
    return R2;
  }

  /// @notice linear interpolation, calculates g(x) = (_rise/_run)x+b
  /// @param _rise x delta, used to calculate, '_rise' in our equation
  /// @param _run y delta, used to calculate '_run' in our equation
  /// @param _distance distance to interpolate. 'x' in our equation
  /// @param _b y intercept, 'b' in our equation
  /// @return _result value of g(x)
  function _linearInterpolation(
    int256 _rise,
    int256 _run,
    int256 _distance,
    int256 _b
  ) private pure returns (int256 _result) {
    // 6 digits of precision should be more than enough
    int256 _mE6 = (_rise * 1e6) / _run;
    // simply multiply the slope by the distance traveled and add the intercept
    // don't forget to unscale the 1e6 by dividing. b is never scaled, and so it is not unscaled
    _result = (_mE6 * _distance) / 1e6 + _b;
    return _result;
  }
}
/// (0, R0)
///      |\
///      | -\
///      |   \
///      |    -\
///      |      -\
///      |        \
///      |         -\
///      |           \
///      |            -\
///      |              -\
///      |                \
///      |                 -\
///      |                   \
///      |                    -\
///      |                      -\
///      |                        \
///      |                         -\
///      |                          ***----\
///      |                     (S1, R1)   ----\
///      |                                       ----\
///      |                                            ----\
///      |                                                 ----\ (S2, R2)
///      |                                                             ***--------------------------------------------------------------\
///      |
///      |
///      |
///      |
///      +---------------------------------------------------------------------------------------------------------------------------------
/// (0,0)                                                                                                                            (100, R2)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title CurveSlave Interface
/// @notice Interface for interacting with CurveSlaves
interface ICurveSlave {
  function valueAt(int256 _xValue) external view returns (int256 _value);
}

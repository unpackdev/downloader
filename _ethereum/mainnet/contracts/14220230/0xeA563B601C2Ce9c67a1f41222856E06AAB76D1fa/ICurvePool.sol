// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICurvePool {
  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy
  ) external returns (uint256);
}
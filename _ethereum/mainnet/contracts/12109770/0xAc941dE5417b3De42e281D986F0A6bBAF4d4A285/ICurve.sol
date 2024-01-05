// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ICurve {
  function exchange(
    int128 from,
    int128 to,
    uint256 _from_amount,
    uint256 _min_to_amount
  ) external;

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
}

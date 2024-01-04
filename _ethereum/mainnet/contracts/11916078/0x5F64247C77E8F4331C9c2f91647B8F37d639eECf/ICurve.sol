// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface ICurve {

  function get_virtual_price()
    external
    view
    returns(uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  )
    external
    view
    returns (uint256);
}

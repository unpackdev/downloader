// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface ICurve {

  function get_virtual_price()
    external
    view
    returns(uint256);
}

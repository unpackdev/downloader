//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./Types.sol";

interface ISwapAction {

    // @dev perform a swap according to the order details. Returns a bool indicating
    // success and a string fail reason.
    function swap(Types.Order calldata order) external returns (bool, string memory failReason);

}
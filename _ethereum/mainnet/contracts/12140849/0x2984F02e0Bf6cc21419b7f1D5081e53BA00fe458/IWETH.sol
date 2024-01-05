//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function withdraw(uint wad) external;
}
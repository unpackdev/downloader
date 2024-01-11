// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";

interface IERC721b is IERC721 {
    function mint(address to, uint256 mintAmount) external;

    function mint(address to) external; 
}
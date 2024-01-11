// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721Enumerable.sol";

interface IBabyBirdez is IERC721Enumerable { 
    function owner() external view returns (address);
}
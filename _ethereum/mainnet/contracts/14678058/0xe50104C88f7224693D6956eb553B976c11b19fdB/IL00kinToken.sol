// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IL00kinToken is IERC20 {
    function maxSupply() external view returns (uint256);

    function mint(address receiver, uint256 amount) external returns (bool);
}
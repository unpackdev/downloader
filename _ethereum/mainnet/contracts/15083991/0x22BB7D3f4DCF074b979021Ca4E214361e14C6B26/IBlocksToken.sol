// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author: BLOCKS

import "./IERC20.sol";

interface IBlocksToken is IERC20 {
    function SUPPLY_CAP() external view returns (uint256);

    function mint(address account, uint256 amount) external returns (bool);
}
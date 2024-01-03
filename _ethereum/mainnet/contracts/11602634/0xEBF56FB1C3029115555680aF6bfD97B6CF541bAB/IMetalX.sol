// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IMetalX is IERC20 {
    function mint(address account, uint256 amount) external returns (bool);

    function cap() external returns (uint256);
}

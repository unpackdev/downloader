// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
interface IFlyGuyzToken is IERC20 {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
}
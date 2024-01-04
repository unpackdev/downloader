// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

interface ICustomERC20 is IERC20 {
    using SafeERC20 for IERC20;

    function burnFrom(address account, uint256 amount) external;
}

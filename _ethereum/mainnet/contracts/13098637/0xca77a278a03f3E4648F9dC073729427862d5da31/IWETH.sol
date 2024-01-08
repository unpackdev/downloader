// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./IERC20Upgradeable.sol";

interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256) external;
}

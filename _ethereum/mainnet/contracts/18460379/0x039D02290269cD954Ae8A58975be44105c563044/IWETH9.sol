//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";

interface IWETH9 is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IBentPool {
    function lpToken() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function harvest() external;
}

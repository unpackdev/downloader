//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20.sol";

interface IGaugeDeposit is IERC20 {
    function withdraw(uint256 _amount) external;

    function deposit(uint256 _amount) external;
}

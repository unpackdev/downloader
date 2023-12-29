// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";

interface IEmergency {
    function emergencyWithdraw(IERC20 token) external ;
}
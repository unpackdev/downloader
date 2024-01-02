// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./FutureStructs.sol";

interface IUserHook {
    function updateUser(address user, FuturesUser memory userData) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyAdmin.sol";

contract RoboFiProxyAdmin is ProxyAdmin {

    function isAdminOf(address proxy) external view returns(bool) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success,) = address(proxy).staticcall(hex"5c60da1b");
        return success;
    }
}
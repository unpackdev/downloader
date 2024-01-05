// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

contract CORE_RLP_Factory {

    address public constant TEAM_PROXY_ADMIN = 0xE02C077bAAe03F1E3827a10088694a6939261D46;
    address public immutable RLP_IMPLEMENTATION;

    constructor(address _rlpImplementation) {
        RLP_IMPLEMENTATION = _rlpImplementation;
    }

    function createRLPToken() public returns (address newToken) {
        newToken = address(new TransparentUpgradeableProxy(RLP_IMPLEMENTATION, TEAM_PROXY_ADMIN, "")); // logic, admin, calldata
    }

}
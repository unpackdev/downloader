// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";

contract CNPYStore is AccessControl {
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
    bool public finalized = false;
    address public implementation;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function setImplementation(address _implementation) external virtual onlyRole(UPGRADER_ROLE) {
        require(!finalized, 'Already finalized');
        implementation = _implementation;
    }

    function finalize() external virtual onlyRole(UPGRADER_ROLE) {
        finalized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IAccessManager.sol";

contract AccessManager is IAccessManager, AccessControl, Ownable {
    bytes32 private constant OPERATIONAL_ADDRESS =
        keccak256("OPERATIONAL_ADDRESS");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addOperationalAddress(address _address) public onlyOwner {
        require(
            isOperationalAddress(_address) == false,
            "AccessManager: This address was added earlier"
        );
        grantRole(OPERATIONAL_ADDRESS, _address);
    }

    function removeOperationalAddress(address _address) public onlyOwner {
        _checkRole(OPERATIONAL_ADDRESS, _address);
        revokeRole(OPERATIONAL_ADDRESS, _address);
    }

    function isOperationalAddress(address _address)
        public
        view
        override
        returns (bool)
    {
        return hasRole(OPERATIONAL_ADDRESS, _address);
    }
}

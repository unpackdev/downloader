// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SnowPatrolBase.sol";
import "./ISnowPatrol.sol";

contract SnowPatrol is ISnowPatrol, SnowPatrolBase {
    bytes32 public override constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public override constant LGE_ROLE = keccak256("LGE");
    bytes32 public override constant PWDR_ROLE = keccak256("PWDR");
    bytes32 public override constant SLOPES_ROLE = keccak256("SLOPES");

    constructor(address addressRegistry)
        public
        SnowPatrolBase(addressRegistry)
    {
        // make owner user the sole superuser
        _initializeRoles(msg.sender);
        _initializeAdmins(msg.sender);
    }

    // inititalize all default roles, make the contract the superuser
    function _initializeRoles(address _deployer) private {
        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        _setupRole(ADMIN_ROLE, _deployer);
        _setupRole(LGE_ROLE, _deployer);
        _setupRole(PWDR_ROLE, _deployer);
        _setupRole(SLOPES_ROLE, _deployer);
    }

     // grant admin role to dev addresses
    function _initializeAdmins(address _deployer) private {
        grantRole(ADMIN_ROLE, _deployer);
       
    }

    function setCoreRoles() 
        external
        override
    {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Only Admins can update contract roles"
        );

        // if 
    }
}
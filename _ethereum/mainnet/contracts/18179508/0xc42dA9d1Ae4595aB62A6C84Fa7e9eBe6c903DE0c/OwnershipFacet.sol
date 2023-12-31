// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LibDiamond.sol";
import "./IERC173Upgradeable.sol";
import "./IrrigationAccessControl.sol";

contract OwnershipFacet is IERC173Upgradeable, IrrigationAccessControl {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
        // revoke default admin and auto irriagte role
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(AUTO_IRRIGATE_ADMIN_ROLE, msg.sender);
        // this sets the default admin for every ROLE created
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        // set SuperAdmin as ADMIN_ROLE also, no need to setRoleAdmin() as it will use DEFAULT_ADMIN_ROLE
        _grantRole(ADMIN_ROLE, _newOwner);
        // make superAdmin have the IRRIGATION_ADMIN_ROLE too.
        _grantRole(AUTO_IRRIGATE_ADMIN_ROLE, _newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

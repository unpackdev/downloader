//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IPermissions.sol";

abstract contract Permissions is IPermissions, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant NODE_OPERATOR_ROLE = keccak256("NODE_OPERATOR_ROLE");
    bytes32 public constant KEY_ADMIN_ROLE = keccak256("KEY_ADMIN_ROLE");

    constructor(){
        
        _setRoleAdmin(MINTER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(BURNER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(NODE_OPERATOR_ROLE, GOVERN_ROLE);
        _setRoleAdmin(KEY_ADMIN_ROLE, GOVERN_ROLE);

    }

    modifier onlyGovernor() {
        require(
            isGovernor(msg.sender),
            "Permissions: Caller is not a governor"
        );
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Permissions: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender), "Permissions: Caller is not a burner");
        _;
    }

    modifier onlyNodeOperator() {
        require(isNodeOperator(msg.sender), "Permissions: Caller is not a node operator");
        _;
    }

    modifier onlyKeyAdmin() {
        require(isKeyAdmin(msg.sender), "Permissions: Caller is not a key admin");
        _;
    }

    /// @notice creates a new role to be maintained
    /// @param role the new role id
    /// @param adminRole the admin role id for `role`
    /// @dev can also be used to update admin of existing role
    function createRole(bytes32 role, bytes32 adminRole)
        public
        override
        onlyGovernor
    {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice grants minter role to address
    /// @param minter new minter
    function grantMinter(address minter) public override onlyGovernor {
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice grants burner role to address
    /// @param burner new burner
    function grantBurner(address burner) public override onlyGovernor {
        grantRole(BURNER_ROLE, burner);
    }

    /// @notice grants node operator role to address
    /// @param nodeOperator new nodeOperator
    function grantNodeOperator(address nodeOperator) public override onlyGovernor {
        grantRole(NODE_OPERATOR_ROLE, nodeOperator);
    }
 
    /// @notice grants key admin role to address
    /// @param keyAdmin new keyAdmin
    function grantKeyAdmin(address keyAdmin) public override onlyGovernor {
        grantRole(KEY_ADMIN_ROLE, keyAdmin);
    }

    /// @notice grants governor role to address
    /// @param governor new governor
    function grantGovernor(address governor) public override onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    /// @notice revokes minter role from address
    /// @param minter ex minter
    function revokeMinter(address minter) public override onlyGovernor {
        revokeRole(MINTER_ROLE, minter);
    }

    /// @notice revokes burner role from address
    /// @param burner ex burner
    function revokeBurner(address burner) public override onlyGovernor {
        revokeRole(BURNER_ROLE, burner);
    }

    /// @notice revokes node operator role from address
    /// @param nodeOperator ex nodeOperator
    function revokeNodeOperator(address nodeOperator) public override onlyGovernor {
        revokeRole(NODE_OPERATOR_ROLE, nodeOperator);
    }

    /// @notice revokes key admin role from address
    /// @param keyAdmin ex keyAdmin
    function revokeKeyAdmin(address keyAdmin) public override onlyGovernor {
        revokeRole(KEY_ADMIN_ROLE, keyAdmin);
    }

    /// @notice revokes governor role from address
    /// @param governor ex governor
    function revokeGovernor(address governor) public override onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    /// @notice checks if address is a minter
    /// @param _address address to check
    /// @return true _address is a minter
    function isMinter(address _address) public view override returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /// @notice checks if address is a burner
    /// @param _address address to check
    /// @return true _address is a burner
    function isBurner(address _address) public view override returns (bool) {
        return hasRole(BURNER_ROLE, _address);
    }

    /// @notice checks if address is a node operator
    /// @param _address address to check
    /// @return true _address is a node operator
    function isNodeOperator(address _address) public view override returns (bool) {
        return hasRole(NODE_OPERATOR_ROLE, _address);
    }

    /// @notice checks if address is a key admin
    /// @param _address address to check
    /// @return true _address is a key admin
    function isKeyAdmin(address _address) public view override returns (bool) {
        return hasRole(KEY_ADMIN_ROLE, _address);
    }


    /// @notice checks if address is a governor
    /// @param _address address to check
    /// @return true _address is a governor
    // only virtual for testing mock override
    function isGovernor(address _address)
        public
        view
        virtual
        override
        returns (bool)
    {
        return hasRole(GOVERN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }

}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./IACLRegistry.sol";

/**
 *  @notice Provides modifiers and internal functions for interacting with the `ACLRegistry`
 *  @dev Derived contracts using `ACLAuth` must also inherit `ContractRegistryAccess`
 *   and override `_getContract`.
 */
abstract contract ACLAuth {
  /**
   *  @dev Equal to keccak256("Keeper")
   */
  bytes32 internal constant KEEPER_ROLE = 0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;

  /**
   *  @dev Equal to keccak256("DAO")
   */
  bytes32 internal constant DAO_ROLE = 0xd0a4ad96d49edb1c33461cebc6fb2609190f32c904e3c3f5877edb4488dee91e;

  /**
   *  @dev Equal to keccak256("GUARDIAN_ROLE")
   */
  bytes32 internal constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;

  /**
   *  @dev Equal to keccak256("ApprovedContract")
   */
  bytes32 internal constant APPROVED_CONTRACT_ROLE = 0xfb639edf4b4a4724b8b9fb42a839b712c82108c1edf1beb051bcebce8e689dc4;

  /**
   *  @dev Equal to keccak256("ACLRegistry")
   */
  bytes32 internal constant ACL_REGISTRY_ID = 0x15fa0125f52e5705da1148bfcf00974823c4381bee4314203ede255f9477b73e;

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  modifier onlyRole(bytes32 role) {
    _requireRole(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has at least one of the given roles
   *  @param roleA bytes32 role ID
   *  @param roleB bytes32 role ID
   */
  modifier onlyRoles(bytes32 roleA, bytes32 roleB) {
    require(_hasRole(roleA, msg.sender) == true || _hasRole(roleB, msg.sender) == true, "you dont have the right role");
    _;
  }

  /**
   *  @notice Require that `msg.sender` has given permission
   *  @param role bytes32 permission ID
   */
  modifier onlyPermission(bytes32 role) {
    _requirePermission(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  modifier onlyApprovedContractOrEOA() {
    _requireApprovedContractOrEOA(msg.sender);
    _;
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   *  @return Whether account has been granted specified role.
   */
  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _aclRegistry().hasRole(role, account);
  }

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  function _requireRole(bytes32 role) internal view {
    _requireRole(role, msg.sender);
  }

  /**
   *  @notice Require that given account has specified role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   */
  function _requireRole(bytes32 role, address account) internal view {
    _aclRegistry().requireRole(role, account);
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   *  @return Whether account has been granted specified permission.
   */
  function _hasPermission(bytes32 permission, address account) internal view returns (bool) {
    return _aclRegistry().hasPermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has specified permission
   *  @param permission bytes32 permission ID
   */
  function _requirePermission(bytes32 permission) internal view {
    _requirePermission(permission, msg.sender);
  }

  /**
   *  @notice Require that given account has specified permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   */
  function _requirePermission(bytes32 permission, address account) internal view {
    _aclRegistry().requirePermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA() internal view {
    _requireApprovedContractOrEOA(msg.sender);
  }

  /**
   *  @notice Require that `account` has the `ApprovedContract` role or is an EOA
   *  @param account address of account to check for role/EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA(address account) internal view {
    _aclRegistry().requireApprovedContractOrEOA(account);
  }

  /**
   *  @notice Return an IACLRegistry interface to the registered ACLRegistry contract
   *  @return IACLRegistry interface to ACLRegistry contract
   */
  function _aclRegistry() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(ACL_REGISTRY_ID));
  }

  /**
   *  @notice Get a contract address by name from the contract registry
   *  @param _name bytes32 contract name
   *  @return contract address
   *  @dev Users of this abstract contract should also inherit from `ContractRegistryAccess`
   *   and override `_getContract` in their implementation.
   */
  function _getContract(bytes32 _name) internal view virtual returns (address);
}

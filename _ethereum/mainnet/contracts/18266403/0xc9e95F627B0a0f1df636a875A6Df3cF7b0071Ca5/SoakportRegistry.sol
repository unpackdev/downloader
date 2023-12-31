// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControlEnumerable.sol";
import "./Allowlist.sol";
import "./Blocklist.sol";
import "./IRegistry.sol";

/**
 * A registry of allowlisted and blocklisted addresses and code hashes. This is intended to
 * be deployed as a shared oracle.
 */
contract SoakportRegistry is
  AccessControlEnumerable,
  Allowlist,
  Blocklist,
  IRegistry
{
  bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(REGISTRY_ADMIN_ROLE, _msgSender());
  }

  /**
  * @notice Checks against the allowlist and blocklist (depending if either is enabled
  * or disabled) to see if the operator is allowed.
  * @dev This function checks the blocklist before checking the allowlist, causing the
  * blocklist to take precedent over the allowlist. Be aware that if an operator is on
  * the blocklist and allowlist, it will still be blocked.
  * @param operator Address of operator
  * @return Bool whether the operator is allowed on based off the registry
  */
  function isAllowedOperator(
    address operator
  )
  external
  view
  virtual
  returns (bool)
  {
    if (isBlocklistDisabled == false) {
      bool blocked = _isBlocked(operator);

      if (blocked) {
        return false;
      }
    }

    if (isAllowlistDisabled == false) {
      bool allowed = _isAllowed(operator);

      return allowed;
    }

    return true;
  }

  /**
  * @notice Global killswitch for the allowlist
  * @param disabled Enables or disables the allowlist
  */
  function setIsAllowlistDisabled(
    bool disabled
  )
  external
  virtual
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    super._setIsAllowlistDisabled(disabled);
  }

  /**
  * @notice Global killswitch for the blocklist
  * @param disabled Enables or disables the blocklist
  */
  function setIsBlocklistDisabled(
    bool disabled
  )
  external
  virtual
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    super._setIsBlocklistDisabled(disabled);
  }

  /**
  * @notice Checks if the operator is on the blocklist
  * @param operator Address of operator
  * @return Bool whether operator is blocked
  */
  function isBlocked(address operator)
  external
  view
  override(IRegistry, Blocklist)
  returns (bool)
  {
    return _isBlocked(operator);
  }

  /**
  * @notice Checks if the operator is on the allowlist
  * @param operator Address of operator
  * @return Bool whether operator is allowed
  */
  function isAllowed(address operator)
  external
  view
  override(IRegistry, Allowlist)
  returns (bool)
  {
    return _isAllowed(operator);
  }

  /**
  * @notice Adds a contract address to the allowlist
  * @param contractAddress Address of allowed operator
  */
  function addAllowedContractAddress(
    address contractAddress
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._addAllowedContractAddress(contractAddress);
  }

  /**
  * @notice Removes a contract address from the allowlist
  * @param contractAddress Address of allowed operator
  */
  function removeAllowedContractAddress(
    address contractAddress
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._removeAllowedContractAddress(contractAddress);
  }

  /**
  * @notice Adds a codehash to the allowlist
  * @param codeHash Code hash of allowed contract
  */
  function addAllowedCodeHash(
    bytes32 codeHash
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._addAllowedCodeHash(codeHash);
  }

  /**
  * @notice Removes a codehash from the allowlist
  * @param codeHash Code hash of allowed contract
  */
  function removeAllowedCodeHash(
    bytes32 codeHash
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._removeAllowedCodeHash(codeHash);
  }

  /**
  * @notice Adds a contract address to the blocklist
  * @param contractAddress Address of blocked operator
  */
  function addBlockedContractAddress(
    address contractAddress
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._addBlockedContractAddress(contractAddress);
  }

  /**
  * @notice Removes a contract address from the blocklist
  * @param contractAddress Address of blocked operator
  */
  function removeBlockedContractAddress(
    address contractAddress
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._removeBlockedContractAddress(contractAddress);
  }

  /**
  * @notice Adds a codehash to the blocklist
  * @param codeHash Code hash of blocked contract
  */
  function addBlockedCodeHash(
    bytes32 codeHash
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._addBlockedCodeHash(codeHash);
  }

  /**
  * @notice Removes a codehash from the blocklist
  * @param codeHash Code hash of blocked contract
  */
  function removeBlockedCodeHash(
    bytes32 codeHash
  )
  external
  virtual
  onlyRole(REGISTRY_ADMIN_ROLE)
  {
    super._removeBlockedCodeHash(codeHash);
  }
}
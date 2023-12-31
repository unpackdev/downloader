// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./UnderlyingStakeable.sol";

/**
 * @title A module for managing access control using hashed inputs
 * @notice This module is used to hash inputs pertaining to access control around various
 * aspects that a developer may care about. For instance, access on a global scope
 * vs a scope that has a reuired input may have different permission
 */
abstract contract AuthorizationManager is UnderlyingStakeable {
  /**
   * tracks which keys are provided which authorization permissions
   * @dev most of the time the keys will be addresses
   * so you will often have to encode the addresses as byte32
   */
  mapping(bytes32 key => uint256 settings) public authorization;
  /**
   * emitted after settings are updated to allow various
   * addresses and key combinations to act on owners behalf
   * @param key the key, usually an address, that is authorized to perform new actions
   * @param settings the settings number - used as binary
   */
  event UpdateAuthorization(bytes32 indexed key, uint256 settings);
  /**
   * the maximum authorization value that a setting can hold
   * @notice - this is enforced during _setAuthorization only so it
   * could be set elsewhere if the contract decides to
   */
  uint256 public immutable MAX_AUTHORIZATION;
  /**
   * Sets up the contract by accepting a value limit during construction.
   * Usually this is type(uint8).max or other derived value
   * @param maxAuthorization the maximum uint that can be set
   * on the authorization manager as a value.
   */
  constructor(uint256 maxAuthorization) {
    MAX_AUTHORIZATION = maxAuthorization;
  }
  /**
   * set the authorization status of an address
   * @param key the address to set the authorization flag of
   * @param settings allowed to start / end / early end stakes
   */
  function _setAuthorization(bytes32 key, uint256 settings) internal {
    if (settings > MAX_AUTHORIZATION) {
      revert NotAllowed();
    }
    authorization[key] = settings;
    emit UpdateAuthorization({
      key: key,
      settings: settings
    });
  }
  /**
   * sets an authorization level for an address
   * @param account the address to scope an authorization value
   * @param settings the settings configuration in uint256 form
   */
  function _setAddressAuthorization(address account, uint256 settings) internal {
    _setAuthorization({
      key: bytes32(uint256(uint160(account))),
      settings: settings
    });
  }
  /**
   * check if an address is authorized to perform an action
   * this index will be different for each implementation
   * @param account the address to verify is authorized to do an action
   * @param index the index of the bit to check
   * @dev the index is an index of the bits as in binary (1/0)
   * @return whether or not the address authorization value has a 1/0 at the provided index
   */
  function isAddressAuthorized(address account, uint256 index) view external returns(bool) {
    return _isAddressAuthorized({
      account: account,
      index: index
    });
  }
  /**
   * check if the provided address is authorized to perform an action
   * @param account the address to check authorization against
   * @param index the index of the setting boolean to check
   * @return whether or not the address authorization value has a 1/0 at the provided index
   */
  function _isAddressAuthorized(address account, uint256 index) view internal returns(bool) {
    return _isAuthorized({
      key: bytes32(uint256(uint160(account))),
      index: index
    });
  }
  /**
   * check the index of the setting for the provided key
   * return true if flag is true
   * @param key the key to check against the authorization mapping
   * @param index the index of the setting flag to check
   * @return whether or not the authorization value has a 1 or a 0 at the provided index
   */
  function _isAuthorized(bytes32 key, uint256 index) view internal returns(bool) {
    return _isOneAtIndex({
      settings: authorization[key],
      index: index
    });
  }
  /**
   * access settings scoped under an account (address) only
   * @param account the account whose settings you wish to access
   * @return arbitrary authorization value
   */
  function _getAddressSettings(address account) view internal returns(uint256) {
    return authorization[bytes32(uint256(uint160(account)))];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Mavia Blacklist
 *
 * @notice This contract is the implementation of blacklist
 *
 * @dev This contract contains logic is only used by owner
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaBlacklist {
  /// @dev blacklist map
  mapping(address => bool) public blacklist;

  event AddBlackList(address[] _addresses);
  event RemoveBlackList(address[] _addresses);

  /**
   * @dev Add blacklist to the contract
   * @param _pAddresses Array of addresses
   */
  function _fAddBlacklist(address[] memory _pAddresses) internal {
    uint256 addressesLength_ = _pAddresses.length;
    for (uint256 i; i < addressesLength_; i++) {
      blacklist[_pAddresses[i]] = true;
    }
    emit AddBlackList(_pAddresses);
  }

  /**
   * @dev Remove blacklist from the contract
   * @param _pAddresses Array of addresses
   */
  function _fRemoveBlacklist(address[] memory _pAddresses) internal {
    uint256 addressesLength_ = _pAddresses.length;
    for (uint256 i; i < addressesLength_; i++) {
      blacklist[_pAddresses[i]] = false;
    }
    emit RemoveBlackList(_pAddresses);
  }
}

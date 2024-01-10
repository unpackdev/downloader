// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @dev The contract manages a list of whitelisted addresses
 */
contract WhitelistUpgradeable is OwnableUpgradeable {
  using AddressUpgradeable for address;

  mapping(address => bool) private whitelist;

  function __Whitelist_init() internal initializer {
    OwnableUpgradeable.__Ownable_init();
    address msgSender = _msgSender();
    whitelist[msgSender] = true;
  }

  /**
   * @dev returns true if a given address is whitelisted, false if not
   *
   * @param _address address to check
   *
   * @return true if the address is whitelisted, false if not
   */
  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  modifier onlyWhitelisted() {
    address sender = _msgSender();
    require(isWhitelisted(sender), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev adds a given address to the whitelist
   *
   * @param _address address to add
   */
  function addAddress(address _address) public onlyWhitelisted {
    if (whitelist[_address])
      // checks if the address is already whitelisted
      return;

    whitelist[_address] = true;
  }

  /**
   * @dev removes a given address from the whitelist
   *
   * @param _address address to remove
   */
  function removeAddress(address _address) public onlyWhitelisted {
    if (!whitelist[_address])
      // checks if the address is actually whitelisted
      return;

    whitelist[_address] = false;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract AddressManager is Ownable {
  mapping(address => bool) public viplist;
  mapping(address => bool) public greenlist;
  mapping(address => bool) public packlist;

  event VipListedAddressAdded(address addr);
  event VipListedAddressRemoved(address addr);
  event GreenListedAddressAdded(address addr);
  event GreenListedAddressRemoved(address addr);
  event PackListedAddressAdded(address addr);
  event PackListedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not VIPlisted.
   */
  modifier onlyViplisted() {
    require(viplist[msg.sender], "Address Not in VIP List");
    _;
  }

  /**
   * @dev Throws if called by any account that's not Greenlisted.
   */
  modifier onlyGreenlisted() {
    require(greenlist[msg.sender], "Address Not in Green List");
    _;
  }

  /**
   * @dev Throws if called by any account that's not VIPlisted.
   */
  modifier onlyPacklisted() {
    require(packlist[msg.sender], "Address Not in Pack List");
    _;
  }

  /**
   * @dev add an address to the viplist
   * @param addr address
   * @return success if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToViplist(address addr) public onlyOwner returns(bool success) {
    if (!viplist[addr]) {
      viplist[addr] = true;
      emit VipListedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the viplist
   * @param addrs addresses
   * @return success if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToViplist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToViplist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the viplist
   * @param addr address
   * @return success if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromViplist(address addr) public onlyOwner returns(bool success) {
    if (viplist[addr]) {
      viplist[addr] = false;
      emit VipListedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the viplist
   * @param addrs addresses
   * @return success if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromViplist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromViplist(addrs[i])) {
        success = true;
      }
    }
  }

    /**
   * @dev add an address to the greenlist
   * @param addr address
   * @return success if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToGreenlist(address addr) public onlyOwner returns(bool success) {
    if (!greenlist[addr]) {
      greenlist[addr] = true;
      emit GreenListedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the greenlist
   * @param addrs addresses
   * @return success if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToGreenlist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToGreenlist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the greenlist
   * @param addr address
   * @return success if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromGreenlist(address addr) public onlyOwner returns(bool success) {
    if (greenlist[addr]) {
      greenlist[addr] = false;
      emit GreenListedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the greenlist
   * @param addrs addresses
   * @return success if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromGreenlist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromGreenlist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev add an address to the packlist
   * @param addr address
   * @return success if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToPacklist(address addr) public onlyOwner returns(bool success) {
    if (!packlist[addr]) {
      packlist[addr] = true;
      emit PackListedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the packlist
   * @param addrs addresses
   * @return success if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToPacklist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToPacklist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the packlist
   * @param addr address
   * @return success if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromPacklist(address addr) public onlyOwner returns(bool success) {
    if (packlist[addr]) {
      packlist[addr] = false;
      emit PackListedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the packlist
   * @param addrs addresses
   * @return success if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromPacklist(address[] memory addrs) public onlyOwner returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromPacklist(addrs[i])) {
        success = true;
      }
    }
  }
}

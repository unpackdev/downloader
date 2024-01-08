//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;
  uint32 public whitelistCount = 0;
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender], "account is not whitelisted");
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return success if the address was added to the whitelist, false if the address was already in the whitelist 
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      whitelistCount++;
      emit WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return success if at least one address was added to the whitelist, 
   * false if all addresses were already in the whitelist  
   */
  function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return success if the address was removed from the whitelist, 
   * false if the address wasn't in the whitelist in the first place 
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      whitelistCount--;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }
/**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return success if the address was removed from the whitelist, 
   * false if the address wasn't in the whitelist in the first place 
   */
  function removeOwnAddressFromWhitelist(address addr) public returns(bool success) {
    require(addr == msg.sender, "can only remove own address");
    if (whitelist[addr]) {
      whitelist[addr] = false;
      whitelistCount--;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }
  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return success if at least one address was removed from the whitelist, 
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}
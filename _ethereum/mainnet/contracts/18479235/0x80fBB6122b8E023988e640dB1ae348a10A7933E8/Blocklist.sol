// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Blocklist
 * @dev This contract allows for the initialization of a blocklist of addresses.
 * Once set, the blocklist cannot be modified.
 */
contract Blocklist {
  mapping(address => bool) private blocklist;

  /**
   * @dev Constructor to initialize the contract's owner.
   */
  constructor(address[] memory blockedAddresses) {
    for (uint i = 0; i < blockedAddresses.length; ) {
      blocklist[blockedAddresses[i]] = true;
      unchecked {
        i += 1;
      }
    }
  }

  /** @dev Check if an address is in the blocklist.
   * @param _address The address to check.
   * @return bool True if the address is in the blocklist, false otherwise.
   */
  function isBlocklisted(address _address) public view returns (bool) {
    return blocklist[_address];
  }
}

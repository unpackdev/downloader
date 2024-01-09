// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Ownable {
  address public owner;

  // Event
  event OwnershipChanged(address indexed oldOwner, address indexed newOwner);

  // Modifier
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor(){
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }
}
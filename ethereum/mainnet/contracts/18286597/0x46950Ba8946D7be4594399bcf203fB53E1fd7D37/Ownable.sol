// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IERC173.sol";

contract Ownable is IERC173 {
  error NotOwner(address _sender, address _owner);
  error InvalidNewOwner();

  address public owner;

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (!isOwner(msg.sender)) revert NotOwner(msg.sender, owner);
    _;
  }

  function isOwner(address _owner) public view returns (bool) {
    return _owner == owner && _owner != address(0);
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    if (_newOwner == address(0)) revert InvalidNewOwner();

    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function rennounceOwnership() external onlyOwner {
    owner = address(0);
    emit OwnershipTransferred(msg.sender, address(0));
  }
}

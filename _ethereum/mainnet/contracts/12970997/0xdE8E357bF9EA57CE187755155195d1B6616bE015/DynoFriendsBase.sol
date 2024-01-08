//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./Ownable.sol";

abstract contract DynoFriendsBase is Ownable, Pausable {
  
  // List of _authorizedAddressList addresses
  mapping(address => bool) internal _authorizedAddressList;

  modifier isOwner() {
    require(_msgSender() == owner(), "DynoFriendsBase: not owner");
    _;
  }

  modifier isAuthorized() {
    require(
      _msgSender() == owner() || _authorizedAddressList[_msgSender()] == true,
      "DynoFriendsBase: unauthorized"
    );
    _;
  }

  function grantAuthorized(address auth_) external isOwner() {
    _authorizedAddressList[auth_] = true;
  }

  function revokeAuthorized(address auth_) external isOwner() {
    _authorizedAddressList[auth_] = false;
  }

  function pause() external isOwner() {
    _pause();
  }

  function unpause() external isOwner() {
    _unpause();
  }
}

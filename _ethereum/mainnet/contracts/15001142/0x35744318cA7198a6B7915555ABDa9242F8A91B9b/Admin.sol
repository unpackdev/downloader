// SPDX-License-Identifier: BSD-3-Clause
// © 2022-present 0xG
pragma solidity ^0.8.0;

// @title Admin
// @author 0xG

abstract contract Admin {
  mapping(address => bool) private _admins;
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AdminSet(address indexed addr, bool indexed add);

  constructor() {
    _owner = msg.sender;
    _admins[msg.sender] = true;
  }

  function owner() external view virtual returns (address) {
    return _owner;
  }

  function setOwner(address newOwner) external adminOnly {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function isAdmin(address addr) external view virtual returns (bool) {
    return true == _admins[addr];
  }

  function setAdmin(address addr, bool add) external adminOnly {
    if (add) {
      _admins[addr] = true;
    } else {
      delete _admins[addr];
    }
    emit AdminSet(addr, add);
  }

  modifier adminOnly {
    require(this.isAdmin(msg.sender), "Admin: caller is not an admin");
    _;
  }
}
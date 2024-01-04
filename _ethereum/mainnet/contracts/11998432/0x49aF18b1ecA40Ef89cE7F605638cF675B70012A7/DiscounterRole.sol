// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Roles.sol";


contract DiscounterRole
{
  using Roles for Roles.Role;

  Roles.Role private _discounters;

  event DiscounterAdded(address indexed account);
  event DiscounterRemoved(address indexed account);

  modifier onlyDiscounter()
  {
    require(isDiscounter(msg.sender), "!discounter");
    _;
  }

  constructor()
  {
    _discounters.add(msg.sender);

    emit DiscounterAdded(msg.sender);
  }

  function isDiscounter(address account) public view returns (bool)
  {
    return _discounters.has(account);
  }

  function addDiscounter(address account) public onlyDiscounter
  {
    _discounters.add(account);

    emit DiscounterAdded(account);
  }

  function renounceDiscounter() public
  {
    _discounters.remove(msg.sender);

    emit DiscounterRemoved(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Roles.sol";


contract PauserRole
{
  using Roles for Roles.Role;

  Roles.Role private _pausers;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  modifier onlyPauser()
  {
    require(isPauser(msg.sender), "!pauser");
    _;
  }

  constructor()
  {
    _pausers.add(msg.sender);

    emit PauserAdded(msg.sender);
  }

  function isPauser(address account) public view returns (bool)
  {
    return _pausers.has(account);
  }

  function addPauser(address account) public onlyPauser
  {
    _pausers.add(account);

    emit PauserAdded(account);
  }

  function renouncePauser() public
  {
    _pausers.remove(msg.sender);

    emit PauserRemoved(msg.sender);
  }
}

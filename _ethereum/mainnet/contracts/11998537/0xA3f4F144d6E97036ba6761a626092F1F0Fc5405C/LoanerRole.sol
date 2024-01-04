// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Roles.sol";


contract LoanerRole
{
  using Roles for Roles.Role;

  Roles.Role private _loaners;

  event LoanerAdded(address indexed account);
  event LoanerRemoved(address indexed account);

  modifier onlyLoaner()
  {
    require(isLoaner(msg.sender), "!loaner");
    _;
  }

  constructor()
  {
    _loaners.add(msg.sender);

    emit LoanerAdded(msg.sender);
  }

  function isLoaner(address account) public view returns (bool)
  {
    return _loaners.has(account);
  }

  function addLoaner(address account) public virtual onlyLoaner
  {
    _loaners.add(account);

    emit LoanerAdded(account);
  }

  function renounceLoaner() public
  {
    _loaners.remove(msg.sender);

    emit LoanerRemoved(msg.sender);
  }
}

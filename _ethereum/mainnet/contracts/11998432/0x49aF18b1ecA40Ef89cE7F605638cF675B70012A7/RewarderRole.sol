// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Roles.sol";


contract RewarderRole
{
  using Roles for Roles.Role;

  Roles.Role private _rewarders;

  event RewarderAdded(address indexed account);
  event RewarderRemoved(address indexed account);

  modifier onlyRewarder()
  {
    require(isRewarder(msg.sender), "!rewarder");
    _;
  }

  constructor()
  {
    _rewarders.add(msg.sender);

    emit RewarderAdded(msg.sender);
  }

  function isRewarder(address account) public view returns (bool)
  {
    return _rewarders.has(account);
  }

  function addRewarder(address account) public onlyRewarder
  {
    _rewarders.add(account);
    emit RewarderAdded(account);
  }

  function renounceRewarder() public
  {
    _rewarders.remove(msg.sender);
    emit RewarderRemoved(msg.sender);
  }
}

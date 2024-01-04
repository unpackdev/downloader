// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./PauserRole.sol";


contract Pausable is PauserRole
{
  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor()
  {
    _paused = false;
  }

  function _isPaused() internal view
  {
    require(_paused, "!paused");
  }

  function _isNotPaused() internal view
  {
    require(!_paused, "Paused");
  }

  function paused() public view returns (bool)
  {
    return _paused;
  }

  function pause() public onlyPauser
  {
    _isNotPaused();

    _paused = true;

    emit Paused(msg.sender);
  }

  function unpause() public onlyPauser
  {
    _isPaused();

    _paused = false;

    emit Unpaused(msg.sender);
  }
}

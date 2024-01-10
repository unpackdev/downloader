// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "./Ownable.sol";
import "./AccessControl.sol";

contract KnitSecurity is Ownable, AccessControl {
  event GloballyPaused(address account);
  event GloballyUnpaused(address account);
  bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

  bool private _globallyPaused;

  constructor () {
      _globallyPaused = false;
      _setupRole(PAUSE_ROLE, msg.sender);
  }
  function isGloballyPaused() public view virtual returns (bool) {
      return _globallyPaused;
  }
  modifier whenNotPaused() {
      require(!isGloballyPaused(), "KnitSecurity: paused");
      _;
  }
  modifier whenPaused() {
      require(isGloballyPaused(), "KnitSecurity: not paused");
      _;
  }
  function pauseGlobally() public whenNotPaused {
    require(hasRole(PAUSE_ROLE, msg.sender), "KnitSecurity: caller is not a pauser");
    _globallyPaused = true;
    emit GloballyPaused(msg.sender);
  }
  function unpauseGlobally() public whenPaused {
    require(hasRole(PAUSE_ROLE, msg.sender), "KnitSecurity: caller is not a pauser");
    _globallyPaused = false;
    emit GloballyUnpaused(msg.sender);
  }
}

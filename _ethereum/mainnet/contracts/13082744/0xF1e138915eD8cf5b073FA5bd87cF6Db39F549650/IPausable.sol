// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

interface IPausable is IGovernable {
  // events
  event PauseChange(bool _paused);

  // errors
  error NoChangeInPause();

  // variables
  function paused() external view returns (bool _paused);

  // methods
  function pause(bool _paused) external;
}

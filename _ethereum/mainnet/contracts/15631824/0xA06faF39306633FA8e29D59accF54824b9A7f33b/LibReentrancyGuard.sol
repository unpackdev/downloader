// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library LibReentrancyGuard {
  using LibVoviStorage for *;

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  function nonReentrant() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
    vs.reentrancyStatus = _ENTERED;
  }

  function completeNonReentrant() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    vs.reentrancyStatus = _NOT_ENTERED;
  }

}
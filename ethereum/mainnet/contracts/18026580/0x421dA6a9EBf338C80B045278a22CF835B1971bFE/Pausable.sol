/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable2Step.sol";
import "./IPausable.sol";

contract Pausable is Ownable2Step, IPausable {

  bool public paused;

  modifier whileNotPaused() {
    require(!paused, "Contract is currently paused");
    _;
  }

  function pause() external onlyOwner {
    paused = true;
    emit contractPaused(address(this));
  }

  function activate() external onlyOwner {
    paused = false;
    emit contractActivated(address(this));
  }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract SpeakToworld {

  event SpeakToWorld(string words);
  
  function speakToWorld(string memory _words) public {
    emit SpeakToWorld(_words);
  }

}
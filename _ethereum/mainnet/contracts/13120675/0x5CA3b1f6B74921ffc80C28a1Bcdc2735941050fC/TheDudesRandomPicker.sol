// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract TheDudesRandomPicker is Ownable {
  uint internal nonce = 1293;
  Pick[] public picks;
  uint public pickCount = 0;

  struct Pick {
    uint id;
    string description;
    uint value;
  }

  function pickRandomValue(string calldata _description, uint _salt, uint _beginValue, uint _limit) public onlyOwner returns (uint) {
    uint r = _beginValue + (uint(keccak256(abi.encodePacked(block.timestamp, nonce, _salt)))) % _limit;
    nonce++;
    picks.push(Pick(pickCount, _description, r));
    pickCount++;
    return r;
  }
}

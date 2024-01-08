// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract ThePixelsRaffle is Ownable, VRFConsumerBase {
  struct Raffle {
    uint256 timestamp;
    uint256 length;
    uint256 seed;
    string description;
  }

  mapping(uint256 => Raffle) public raffles;
  mapping(bytes32 => uint256) public requestIdToRequestNumberIndex;
  uint256 public requestCounter;

  bytes32 internal keyHash;
  uint256 internal fee;

  constructor()
    VRFConsumerBase(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
      0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
  {
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 2 LINK
  }

  function addRaffle(uint256 length, string memory description) external onlyOwner {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

    raffles[requestCounter].timestamp = block.timestamp;
    raffles[requestCounter].length = length;
    raffles[requestCounter].description = description;

    bytes32 requestId =  requestRandomness(keyHash, fee);
    requestIdToRequestNumberIndex[requestId] = requestCounter;
    requestCounter += 1;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint256 raffleIndex = requestIdToRequestNumberIndex[requestId];
    raffles[raffleIndex].seed = randomness;
  }

  function getWinner(uint256 raffleIndex, uint256 winnerIndex) external view returns (uint256) {
    uint256 timestamp = raffles[raffleIndex].timestamp;
    uint256 seed = raffles[raffleIndex].seed;
    require(seed != 0, "Invalid seed");
    uint256 length = raffles[raffleIndex].length;
    return uint256(keccak256(abi.encodePacked(timestamp, seed, length, winnerIndex))) % length;
  }
}

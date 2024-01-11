// SPDX-License-Identifier: MIT
// Keylionnaire is the April 18th giveaway contract for the Meta Mansions project of 444 ETH
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Keylionnaire is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;

  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

  bytes32 keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;

  uint32 callbackGasLimit = 100000;

  uint16 requestConfirmations = 3;

  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  uint256 constant public count = 4444;
  uint256 public randomlyChosenNumber;

  event WinningNumberSeed(uint256 seed);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function chooseWinners() public onlyOwner {
      require (randomlyChosenNumber == 0, "Seed has already been chosen!");
      
      randomlyChosenNumber = s_randomWords[0];

      emit WinningNumberSeed(randomlyChosenNumber);
  }

    /* 
        After chooseWinners() saves a randomly chosen number using the Chainlink VRF,
        it becomes a seed (chosen in a provably fair manner)

        Each "winner" is determined by combining that randomly
        chosen number by an "index", and hashing it.

        The largest winner will be index  = 0
        The next 11 winners will be index = 1, 2, 3, 4, ..., 12

        If any team members "win", they're disqualified, so we
        simply ignore them and draw an additional number.
        
        For example: If team member wins on index = 8, then
        largest winner = 0, others = 1 2 3 4 5 6 7 9 10 11 12 13

        For example: If a team member wins the largest prize, then
        largest winner = 1, others = 2 3 4 5 6 7 8 9 10 11 12 13

        For example: If a team member wins 9 10 and 11, then
        largest winner = 0, others = 1 2 3 4 5 6 7 8 12 13 14 15

        If a duplicate number is chosen, it's also disqualified
        and we treat the same way (a person can only win once)

        This returns a number between 0 and 4443
        There are 4444 potential winning mansion ids, and we sort them in
        ascending order
        The lowest potential winner number corresponds to 0
        The highest number corresponds to 4443
    */

    function winner(uint256 index) public view returns (uint16) {
        require(randomlyChosenNumber != 0, "Call chooseWinners first");

        uint256 number = uint256(keccak256(abi.encodePacked(randomlyChosenNumber, index)));

        return (uint16)(number % count);
    }
}

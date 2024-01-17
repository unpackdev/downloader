// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract MetatopiaCoinFlipRNG is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 2;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  address public BetContract;
  uint256 private lastWord;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    uint256[] memory initialWords = new uint256[](1);
    s_randomWords = initialWords;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyBetContract() {
    lastWord = s_randomWords[0];
    // Will revert if subscription is not set and funded.
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

  function oneOutOfTwo() external view onlyBetContract() returns (uint256 result) {
    require(s_randomWords[0] != lastWord, "Too Soon, please wait for new number generation");
    result = (s_randomWords[0] % 2);
    return result;
  }

  function setBetContract(address _address) external onlyOwner {
    BetContract = _address;
  }

  function setCallbackGas(uint32 _gas) external onlyOwner {
    callbackGasLimit = _gas;
  }

  modifier onlyBetContract() {
    require(msg.sender == BetContract , "Only Bet.sol");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}

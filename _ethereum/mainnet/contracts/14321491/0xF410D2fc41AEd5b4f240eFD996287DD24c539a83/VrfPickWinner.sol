// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract VrfPickWinner is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  uint64 public s_subscriptionId;

  uint public s_totalPledged;

  address public vrfCoordinator;

  address public link;

  bytes32 public keyHash;

  uint32 public callbackGasLimit = 1000000;

  uint16 public requestConfirmations = 3;

  uint32 public numWords = 22;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address public s_owner;

  event LogNewRandomNumber(uint num, uint index);

  constructor(
    uint64 subscriptionId,
    uint totalPledged,
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    s_totalPledged = totalPledged;
    vrfCoordinator = _vrfCoordinator;
    link = _link;
    keyHash = _keyHash;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
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
    for (uint i = 0; i < randomWords.length; i++) {
      s_randomWords.push((randomWords[i] % s_totalPledged) + 1);
      emit LogNewRandomNumber(s_randomWords[i], i);
    }
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}

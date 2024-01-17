// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Randomizer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  address public VaultContract;
  uint256 private lastWord;
  bool public requestPending = false;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    uint256[] memory initialWords = new uint256[](1);
    s_randomWords = initialWords;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyVaultContract() {
    require(!requestPending, "Please wait for previous request to be fulfilled");
    lastWord = s_randomWords[0];
    requestPending = true;

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256,
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  function getRandomWord() external onlyVaultContract() returns (uint256 result) {
    require(s_randomWords[0] != lastWord, "Too Soon, please wait for new number generation");
    result = s_randomWords[0];
    requestPending = false;
    return result;
  }

  function setVaultContract(address _address) external onlyOwner {
    VaultContract = _address;
  }

  function setCallbackGas(uint32 _gas) external onlyOwner {
    callbackGasLimit = _gas;
  }

  // Function to override the requestPending Bool in case of stuck request.
  function emergencyOverridePending(bool _flag) external onlyOwner {
    requestPending = _flag;
  }

  modifier onlyVaultContract() {
    require(msg.sender == VaultContract , "Only Vault");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}

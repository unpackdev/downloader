// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./VRFConsumerBase.sol";

contract Raffle is VRFConsumerBase {
  bytes32 public immutable keyHash;
  uint256 public immutable fee;
  uint256 private randomIndex;

  address public immutable owner;
  string public ticketsList;
  string public resultsList;

  event RandomNumberRequested(address indexed requester);
  event RandomNumberFulfilled(uint256 indexed randomNumber);
  event ResultsPublished(string indexed resultsLink);

  error ResultsAlreadyPublished();
  error NotEnoughLINK();
  error InvalidConstructorParameters();
  error NotOwner();

  modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
  }

  constructor(
      address _vrfCoordinator,
      address _link,
      bytes32 _keyHash,
      uint256 _fee,
      string memory _ticketsList
  ) VRFConsumerBase(_vrfCoordinator, _link) {
      if (_keyHash == bytes32(0) || _fee == 0 || bytes(_ticketsList).length == 0) {
          revert InvalidConstructorParameters();
      }

      keyHash = _keyHash;
      fee = _fee;
      owner = msg.sender;
      ticketsList = _ticketsList;
  }

  function getRandomNumber() external onlyOwner {
      if (LINK.balanceOf(address(this)) < fee) {
          revert NotEnoughLINK();
      }
      if (randomIndex != 0) {
          revert ResultsAlreadyPublished();
      }

      requestRandomness(keyHash, fee);
      emit RandomNumberRequested(msg.sender);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
      randomIndex = randomness;
      emit RandomNumberFulfilled(randomness);
  }

  function getRandomIndex() external view returns (uint256) {
      return randomIndex;
  }

  function publishResults(string calldata _resultsLink) external onlyOwner {
      if (bytes(resultsList).length > 0) {
          revert ResultsAlreadyPublished();
      }

      resultsList = _resultsLink;
      emit ResultsPublished(_resultsLink);
  }
}
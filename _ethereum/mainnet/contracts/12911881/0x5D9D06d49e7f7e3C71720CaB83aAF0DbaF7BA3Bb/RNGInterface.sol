// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface RNGInterface {
  event RandomNumberRequested(uint32 indexed requestId, address indexed sender);
  event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

  function getLastRequestId() external view returns (uint32 requestId);
  function getRequestFee() external view returns (address feeToken, uint256 requestFee);
  function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);
  function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);
  function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}
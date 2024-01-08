// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";

import "./RNGInterface.sol";

contract RNGBlockhash is RNGInterface, Ownable {
  using SafeMath for uint256;
  using SafeCast for uint256;

  uint32 internal requestCount;
  mapping(uint32 => uint256) internal randomNumbers;
  mapping(uint32 => uint32) internal requestLockBlock;
 
  constructor() public { }

  function getLastRequestId() external override view returns (uint32 requestId) {
    return requestCount;
  }

  function getRequestFee() external override view returns (address feeToken, uint256 requestFee) {
    return (address(0), 0);
  }

  function requestRandomNumber() external virtual override returns (uint32 requestId, uint32 lockBlock) {
    requestId = _getNextRequestId();
    lockBlock = uint32(block.number);
    requestLockBlock[requestId] = lockBlock;
    emit RandomNumberRequested(requestId, msg.sender);
  }

  function isRequestComplete(uint32 requestId) external virtual override view returns (bool isCompleted) {
    return _isRequestComplete(requestId);
  }

  function randomNumber(uint32 requestId) external virtual override returns (uint256 randomNum) {
    require(_isRequestComplete(requestId), "RNGBLOCKHASH: REQUEST_INCOMPLETE");

    if (randomNumbers[requestId] == 0) {
      _storeResult(requestId, _getSeed());
    }

    return randomNumbers[requestId];
  }

  function _isRequestComplete(uint32 requestId) internal view returns (bool) {
    return block.number > (requestLockBlock[requestId] + 1);
  }

  function _getNextRequestId() internal returns (uint32 requestId) {
    requestCount = uint256(requestCount).add(1).toUint32();
    requestId = requestCount;
  }

  function _getSeed() internal virtual view returns (uint256 seed) {
    return uint256(blockhash(block.number - 1));
  }

  function _storeResult(uint32 requestId, uint256 result) internal {
    randomNumbers[requestId] = result;
    emit RandomNumberCompleted(requestId, result);
  }
}
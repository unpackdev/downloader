// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./Ownable.sol";
import "./SafeCast.sol";

import "./VRFConsumerBase.sol";
import "./RNGInterface.sol";

contract RNGChainlink is RNGInterface, VRFConsumerBase, Ownable {
  using SafeCast for uint256;

  event KeyHashSet(bytes32 keyHash);
  event FeeSet(uint256 fee);
  event VrfCoordinatorSet(address indexed vrfCoordinator);
  event VRFRequested(uint256 indexed requestId, bytes32 indexed chainlinkRequestId);

  bytes32 public keyHash;
  uint256 public fee;
  uint32 public requestCount;
  mapping(uint32 => uint256) internal randomNumbers;
  mapping(uint32 => uint32) internal requestLockBlock;
  mapping(bytes32 => uint32) internal chainlinkRequestIds;

  constructor(address _vrfCoordinator, address _link)
    public
    VRFConsumerBase(_vrfCoordinator, _link)
  {
    emit VrfCoordinatorSet(_vrfCoordinator);
  }

  function getLink() external view returns (address) {
    return address(LINK);
  }

  function setKeyhash(bytes32 _keyhash) external onlyOwner {
    keyHash = _keyhash;
    emit KeyHashSet(keyHash);
  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
    emit FeeSet(fee);
  }

  function getLastRequestId() external override view returns (uint32 requestId) {
    return requestCount;
  }

  function getRequestFee() external override view returns (address feeToken, uint256 requestFee) {
    return (address(LINK), fee);
  }

  function requestRandomNumber() external override returns (uint32 requestId, uint32 lockBlock) {
    uint256 seed = _getSeed();
    lockBlock = uint32(block.number);

    require(LINK.transferFrom(msg.sender, address(this), fee), "RNGCHAINLINK: FEE_TRANSFER_FAILED");
    
    requestId = _requestRandomness(seed);
    requestLockBlock[requestId] = lockBlock;
    emit RandomNumberRequested(requestId, msg.sender);
  }

  function isRequestComplete(uint32 requestId) external override view returns (bool isCompleted) {
    return randomNumbers[requestId] != 0;
  }

  function randomNumber(uint32 requestId) external override returns (uint256 randomNum) {
    return randomNumbers[requestId];
  }

  function _requestRandomness(uint256 seed) internal returns (uint32 requestId) {
    requestId = _getNextRequestId();
    bytes32 vrfRequestId = requestRandomness(keyHash, fee, seed);
    chainlinkRequestIds[vrfRequestId] = requestId;

    emit VRFRequested(requestId, vrfRequestId);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint32 internalRequestId = chainlinkRequestIds[requestId];
    randomNumbers[internalRequestId] = randomness;
    emit RandomNumberCompleted(internalRequestId, randomness);
  }

  function _getNextRequestId() internal returns (uint32 requestId) {
    requestCount = uint256(requestCount).add(1).toUint32();
    requestId = requestCount;
  }

  function _getSeed() internal virtual view returns (uint256 seed) {
    return uint256(blockhash(block.number - 1));
  }
}
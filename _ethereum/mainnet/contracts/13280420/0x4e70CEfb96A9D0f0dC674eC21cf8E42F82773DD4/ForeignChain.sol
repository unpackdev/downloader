// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./Registry.sol";
import "./BaseChain.sol";

contract ForeignChain is BaseChain {
  // we will not be changing replicator that often, so we can make it immutable, it saves 200gas
  address public immutable replicator;
  uint32 public lastBlockId;
  bool public deprecated;

  // ========== EVENTS ========== //

  event LogBlockReplication(address indexed minter, uint32 blockId);
  event LogDeprecation(address indexed deprecator);

  // ========== CONSTRUCTOR ========== //

  constructor(
    address _contractRegistry,
    uint16 _padding,
    uint16 _requiredSignatures,
    address _replicator
  ) public BaseChain(_contractRegistry, _padding, _requiredSignatures) {
    replicator = _replicator;
  }

  modifier onlyReplicator() {
    require(msg.sender == replicator, "onlyReplicator");
    _;
  }

  // ========== MUTATIVE FUNCTIONS ========== //

  function register() override external {
    require(msg.sender == address(contractRegistry), "only contractRegistry can register");

    ForeignChain oldChain = ForeignChain(contractRegistry.getAddress("Chain"));
    require(address(oldChain) != address(this), "registration must be done before address in registry is replaced");

    if (address(oldChain) != address(0x0)) {
      lastBlockId = oldChain.lastBlockId();
      // we cloning last block time, because we will need reference point for next submissions
      blocks[lastBlockId].dataTimestamp = oldChain.getBlockTimestamp(lastBlockId);
    }
  }

  function unregister() override external {
    require(msg.sender == address(contractRegistry), "only contractRegistry can unregister");
    require(!deprecated, "contract is already deprecated");

    ForeignChain newChain = ForeignChain(contractRegistry.getAddress("Chain"));
    require(address(newChain) != address(this), "unregistering must be done after address in registry is replaced");
    require(newChain.isForeign(), "can not be replaced with chain of different type");

    deprecated = true;
    emit LogDeprecation(msg.sender);
  }

  function submit(
    uint32 _dataTimestamp,
    bytes32 _root,
    bytes32[] calldata _keys,
    uint256[] calldata _values,
    uint32 _blockId
  ) external onlyReplicator {
    require(!deprecated, "contract is deprecated");
    uint lastDataTimestamp = blocks[lastBlockId].dataTimestamp;

    require(blocks[_blockId].dataTimestamp == 0, "blockId already taken");
    require(lastDataTimestamp < _dataTimestamp, "can NOT submit older data");
    require(lastDataTimestamp + padding < block.timestamp, "do not spam");
    require(_keys.length == _values.length, "numbers of keys and values not the same");

    for (uint256 i = 0; i < _keys.length; i++) {
      require(uint224(_values[i]) == _values[i], "FCD overflow");
      fcds[_keys[i]] = FirstClassData(uint224(_values[i]), _dataTimestamp);
    }

    blocks[_blockId] = Block(_root, _dataTimestamp);
    lastBlockId = _blockId;

    emit LogBlockReplication(msg.sender, _blockId);
  }

  // ========== VIEWS ========== //

  function isForeign() override external pure returns (bool) {
    return true;
  }

  function getName() override external pure returns (bytes32) {
    return "Chain";
  }

  function getStatus() external view returns(
    uint256 blockNumber,
    uint16 timePadding,
    uint32 lastDataTimestamp,
    uint32 lastId,
    uint32 nextBlockId
  ) {
    blockNumber = block.number;
    timePadding = padding;
    lastId = lastBlockId;
    lastDataTimestamp = blocks[lastId].dataTimestamp;
    nextBlockId = getBlockIdAtTimestamp(block.timestamp + 1);
  }

  // this function does not works for past timestamps
  function getBlockIdAtTimestamp(uint256 _timestamp) override public view  returns (uint32) {
    uint32 _lastId = lastBlockId;

    if (blocks[_lastId].dataTimestamp == 0) {
      return 0;
    }

    if (blocks[_lastId].dataTimestamp + padding < _timestamp) {
      return _lastId + 1;
    }

    return _lastId;
  }

  function getLatestBlockId() override public view returns (uint32) {
    return lastBlockId;
  }
}

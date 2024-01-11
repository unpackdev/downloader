// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./RLPReader.sol";
import "./MerklePatriciaProof.sol";
import "./Merkle.sol";
import "./ExitPayloadReader.sol";

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
  struct HeaderBlock {
    bytes32 root;
    uint256 start;
    uint256 end;
    uint256 createdAt;
    address proposer;
  }

  mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel is Ownable {
  using RLPReader for RLPReader.RLPItem;
  using Merkle for bytes32;
  using ExitPayloadReader for bytes;
  using ExitPayloadReader for ExitPayloadReader.ExitPayload;
  using ExitPayloadReader for ExitPayloadReader.Log;
  using ExitPayloadReader for ExitPayloadReader.LogTopics;
  using ExitPayloadReader for ExitPayloadReader.Receipt;

  bytes32 public constant SEND_MESSAGE_EVENT_SIG =
    0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

  IFxStateSender public fxRoot;
  ICheckpointManager public checkpointManager;
  address public fxChildTunnel;

  mapping(bytes32 => bool) public processedExits;

  constructor(address _checkpointManager, address _fxRoot) {
    checkpointManager = ICheckpointManager(_checkpointManager);
    fxRoot = IFxStateSender(_fxRoot);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // FROM CHILD
  ////////////////////////////////////////////////////////////////////////////////
  function receiveMessage(bytes memory inputData) public virtual {
    bytes memory message = _validateAndExtractMessage(inputData);
    _processMessageFromChild(message);
  }

  function _processMessageFromChild(bytes memory message) internal virtual;

  function _validateAndExtractMessage(bytes memory inputData)
    internal
    returns (bytes memory)
  {
    ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

    bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
    uint256 blockNumber = payload.getBlockNumber();
    // checking if exit has already been processed
    // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
    bytes32 exitHash = keccak256(
      abi.encodePacked(
        blockNumber,
        // first 2 nibbles are dropped while generating nibble array
        // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
        // so converting to nibble array and then hashing it
        MerklePatriciaProof._getNibbleArray(branchMaskBytes),
        payload.getReceiptLogIndex()
      )
    );
    require(processedExits[exitHash] == false, "FxRT: EXIT_ALREADY_PROCESSED");
    processedExits[exitHash] = true;

    ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
    ExitPayloadReader.Log memory log = receipt.getLog();

    require(fxChildTunnel == log.getEmitter(), "FxRT: INVALID_FX_CHILD_TUNNEL");

    bytes32 receiptRoot = payload.getReceiptRoot();
    require(
      MerklePatriciaProof.verify(
        receipt.toBytes(),
        branchMaskBytes,
        payload.getReceiptProof(),
        receiptRoot
      ),
      "FxRT: INVALID_RECEIPT_PROOF"
    );

    _checkBlockMembershipInCheckpoint(
      blockNumber,
      payload.getBlockTime(),
      payload.getTxRoot(),
      receiptRoot,
      payload.getHeaderNumber(),
      payload.getBlockProof()
    );

    ExitPayloadReader.LogTopics memory topics = log.getTopics();

    require(
      bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG,
      "FxRT: INVALID_SIGNATURE"
    );

    bytes memory message = abi.decode(log.getData(), (bytes));
    return message;
  }

  function _checkBlockMembershipInCheckpoint(
    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    uint256 headerNumber,
    bytes memory blockProof
  ) private view returns (uint256) {
    (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager
      .headerBlocks(headerNumber);

    require(
      keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot))
        .checkMembership(blockNumber - startBlock, headerRoot, blockProof),
      "FxRT: INVALID_HEADER"
    );
    return createdAt;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // TO CHILD
  ////////////////////////////////////////////////////////////////////////////////
  function _sendMessageToChild(bytes memory message) internal {
    fxRoot.sendMessageToChild(fxChildTunnel, message);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // MISC
  ////////////////////////////////////////////////////////////////////////////////
  function setFxChildTunnel(address _fxChildTunnel) public virtual onlyOwner {
    fxChildTunnel = _fxChildTunnel;
  }
}

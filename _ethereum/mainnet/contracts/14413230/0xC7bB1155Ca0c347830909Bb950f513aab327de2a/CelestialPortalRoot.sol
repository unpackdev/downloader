// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";

import "./RLPReader.sol";
import "./MerklePatriciaProof.sol";
import "./Merkle.sol";
import "./ExitPayloadReader.sol";

/**
 * @title Celestial Portal Root
 * @notice Edited from fx-portal/contracts and EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialPortalRoot is Ownable {
  using RLPReader for RLPReader.RLPItem;
  using Merkle for bytes32;
  using ExitPayloadReader for bytes;
  using ExitPayloadReader for ExitPayloadReader.ExitPayload;
  using ExitPayloadReader for ExitPayloadReader.Log;
  using ExitPayloadReader for ExitPayloadReader.LogTopics;
  using ExitPayloadReader for ExitPayloadReader.Receipt;

  /// @notice Emited when we replay a call.
  event CallMade(address target, bool success, bytes data);

  /// @notice Hashed message event -> keccak256("MessageSent(bytes)").
  bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

  /// @notice Fx Root contract address.
  address public fxRoot;
  /// @notice Checkpoint Manager contract address.
  address public checkpointManager;

  /// @notice Polyland Portal contract address.
  address public polylandPortal;

  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Message exits mapping.
  mapping(bytes32 => bool) public processedExits;

  /// @notice Require the sender to be the owner or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "CelestialPortalRoot: Unauthorized to use the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(
    address newFxRoot,
    address newCheckpointManager,
    address newPolylandPortal
  ) external onlyOwner {
    fxRoot = newFxRoot;
    checkpointManager = newCheckpointManager;
    polylandPortal = newPolylandPortal;
  }

  /// @notice Give authentication to `adds_`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 index = 0; index < addresses.length; index++) {
      auth[addresses[index]] = authorized;
    }
  }

  /// @notice Send a message to the portal via FxRoot.
  function sendMessage(bytes calldata message) external onlyAuth {
    IFxStateSender(fxRoot).sendMessageToChild(polylandPortal, message);
  }

  /// @notice Clone reflection calls by the owner.
  function replayCall(
    address target_,
    bytes calldata data_,
    bool required_
  ) external onlyOwner {
    (bool succ, ) = target_.call(data_);
    if (required_) require(succ, "CelestialPortalRoot: Replay call failed");
  }

  /**
   * @notice Executed when we receive a message from Polyland.
   * @dev This function verifies if the transaction actually happened on child chain.
   * @param data RLP encoded data of the reference tx containing following list of fields
   *  0 - headerNumber - Checkpoint header block number containing the reference tx
   *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
   *  2 - blockNumber - Block number containing the reference tx on child chain
   *  3 - blockTime - Reference tx block time
   *  4 - txRoot - Transactions root of block
   *  5 - receiptRoot - Receipts root of block
   *  6 - receipt - Receipt of the reference transaction
   *  7 - receiptProof - Merkle proof of the reference receipt
   *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
   *  9 - receiptLogIndex - Log Index to read from the receipt
   */
  function receiveMessage(bytes calldata data) public virtual {
    bytes memory message = _validateAndExtractMessage(data);
    (address target, bytes[] memory calls) = abi.decode(message, (address, bytes[]));
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, ) = target.call(calls[i]);
      emit CallMade(target, success, calls[i]);
    }
  }

  /// @notice Validate and extract message from FxRoot.
  function _validateAndExtractMessage(bytes memory data) internal returns (bytes memory) {
    ExitPayloadReader.ExitPayload memory payload = data.toExitPayload();

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
    require(processedExits[exitHash] == false, "CelestialPortalRoot: EXIT_ALREADY_PROCESSED");
    processedExits[exitHash] = true;

    ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
    ExitPayloadReader.Log memory log = receipt.getLog();

    // check child tunnel
    require(polylandPortal == log.getEmitter(), "CelestialPortalRoot: INVALID_FX_CHILD_TUNNEL");

    bytes32 receiptRoot = payload.getReceiptRoot();
    // verify receipt inclusion
    require(
      MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
      "CelestialPortalRoot: INVALID_RECEIPT_PROOF"
    );

    // verify checkpoint inclusion
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
      bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
      "CelestialPortalRoot: INVALID_SIGNATURE"
    );

    // received message data
    bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
    return message;
  }

  /// @notice Validate checkpoint payload.
  function _checkBlockMembershipInCheckpoint(
    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    uint256 headerNumber,
    bytes memory blockProof
  ) internal view returns (uint256) {
    (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = ICheckpointManager(checkpointManager)
      .headerBlocks(headerNumber);

    require(
      keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
        blockNumber - startBlock,
        headerRoot,
        blockProof
      ),
      "CelestialPortalRoot: INVALID_HEADER"
    );
    return createdAt;
  }
}

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
  function headerBlocks(uint256 headerBlock)
    external
    view
    returns (
      bytes32 root,
      uint256 start,
      uint256 end,
      uint256 createdAt,
      address proposer
    );
}

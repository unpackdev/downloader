// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./ICrossDomainMessenger.sol";

import "./IMessageExecutor.sol";
import "./ISingleMessageDispatcher.sol";
import "./IBatchedMessageDispatcher.sol";

import "./MessageLib.sol";

/**
 * @title MessageDispatcherOptimism contract
 * @notice The MessageDispatcherOptimism contract allows a user or contract to send messages from Ethereum to Optimism.
 *         It lives on the Ethereum chain and communicates with the `MessageExecutorOptimism` contract on the Optimism chain.
 */
contract MessageDispatcherOptimism is ISingleMessageDispatcher, IBatchedMessageDispatcher {
  /* ============ Variables ============ */

  /// @notice Address of the Optimism cross domain messenger on the Ethereum chain.
  ICrossDomainMessenger public immutable crossDomainMessenger;

  /// @notice Address of the executor contract on the Optimism chain.
  IMessageExecutor internal executor;

  /// @notice Nonce used to compute unique `messageId`s.
  uint256 internal nonce;

  /// @notice ID of the chain receiving the dispatched messages. i.e.: 10 for Mainnet, 420 for Goerli.
  uint256 internal immutable toChainId;

  /// @notice Gas limit at which the transaction is executed on L2 when calling `dispatchMessage`.
  uint32 internal immutable gasLimit;

  /* ============ Constructor ============ */

  /**
   * @notice MessageDispatcherOptimism constructor.
   * @param _crossDomainMessenger Address of the Optimism cross domain messenger
   * @param _toChainId ID of the chain receiving the dispatched messages
   * @param _gasLimit Gas limit at which the transaction is executed on L2 when calling `dispatchMessage`
   */
  constructor(ICrossDomainMessenger _crossDomainMessenger, uint256 _toChainId, uint32 _gasLimit) {
    require(address(_crossDomainMessenger) != address(0), "Dispatcher/CDM-not-zero-address");
    require(_toChainId != 0, "Dispatcher/chainId-not-zero");

    crossDomainMessenger = _crossDomainMessenger;
    toChainId = _toChainId;
    gasLimit = _gasLimit;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc ISingleMessageDispatcher
  function dispatchMessage(
    uint256 _toChainId,
    address _to,
    bytes calldata _data
  ) external returns (bytes32) {
    return _dispatchMessage(_toChainId, _to, _data, gasLimit);
  }

  /**
   * @notice Dispatch and process a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _to Address on the receiving chain that will receive `data`
   * @param _data Data dispatched to the receiving chain
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   * @return bytes32 ID uniquely identifying the message
   */
  function dispatchMessageWithGasLimit(
    uint256 _toChainId,
    address _to,
    bytes calldata _data,
    uint32 _gasLimit
  ) external returns (bytes32) {
    return _dispatchMessage(_toChainId, _to, _data, _gasLimit);
  }

  /// @inheritdoc IBatchedMessageDispatcher
  function dispatchMessageBatch(
    uint256 _toChainId,
    MessageLib.Message[] calldata _messages
  ) external returns (bytes32) {
    return _dispatchMessageBatch(_toChainId, _messages, gasLimit);
  }

  /**
   * @notice Dispatch and process `messages` to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the `messages`.
   * @dev Must emit the `MessageBatchDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _messages Array of Message dispatched
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   * @return bytes32 ID uniquely identifying the `messages`
   */
  function dispatchMessageWithGasLimitBatch(
    uint256 _toChainId,
    MessageLib.Message[] calldata _messages,
    uint32 _gasLimit
  ) external returns (bytes32) {
    return _dispatchMessageBatch(_toChainId, _messages, _gasLimit);
  }

  /// @inheritdoc IMessageDispatcher
  function getMessageExecutorAddress(uint256 _toChainId) external view returns (address) {
    return _getMessageExecutorAddress(_toChainId);
  }

  /**
   * @notice Set executor contract address.
   * @dev Will revert if it has already been set.
   * @param _executor Address of the executor contract on the Optimism chain
   */
  function setExecutor(IMessageExecutor _executor) external {
    require(address(executor) == address(0), "Dispatcher/executor-already-set");
    executor = _executor;
  }

  /* ============ Internal Functions ============ */

  /* ============ Require Functions ============ */

  /**
   * @notice Check toChainId to ensure messages can be dispatched to this chain.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain receiving the message
   */
  function _checkToChainId(uint256 _toChainId) internal view {
    require(_toChainId == toChainId, "Dispatcher/chainId-not-supported");
  }

  /**
   * @notice Check dispatch parameters to ensure messages can be dispatched.
   * @dev Will revert if `executor` is not set.
   * @param _executor Address of the executor contract on the Optimism chain
   */
  function _checkExecutor(address _executor) internal pure {
    require(_executor != address(0), "Dispatcher/executor-not-set");
  }

  /* ============ Getter Functions ============ */

  /**
   * @notice Retrieves address of the MessageExecutor contract on the receiving chain.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain with which MessageDispatcher is communicating
   * @return address MessageExecutor contract address
   */
  function _getMessageExecutorAddress(uint256 _toChainId) internal view returns (address) {
    _checkToChainId(_toChainId);
    return address(executor);
  }

  /* ============ State Functions ============ */

  /**
   * @notice Helper to increment nonce.
   * @return uint256 Incremented nonce
   */
  function _incrementNonce() internal returns (uint256) {
    unchecked {
      nonce++;
    }

    return nonce;
  }

  /* ============ Dispatch Functions ============ */

  /**
   * @notice Dispatch a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _to Address on the receiving chain that will receive `data`
   * @param _data Data dispatched to the receiving chain
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   * @return bytes32 ID uniquely identifying the message
   */
  function _dispatchMessage(
    uint256 _toChainId,
    address _to,
    bytes calldata _data,
    uint32 _gasLimit
  ) internal returns (bytes32) {
    address _executorAddress = _getMessageExecutorAddress(_toChainId);
    _checkExecutor(_executorAddress);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageId(_nonce, msg.sender, _to, _data);

    _sendMessage(
      _executorAddress,
      MessageLib.encodeMessage(_to, _data, _messageId, block.chainid, msg.sender),
      _gasLimit
    );

    emit MessageDispatched(_messageId, msg.sender, _toChainId, _to, _data);

    return _messageId;
  }

  /**
   * @notice Dispatch `messages` to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the `messages`.
   * @dev Must emit the `MessageBatchDispatched` event when successfully dispatched.
   * @param _toChainId ID of the receiving chain
   * @param _messages Array of Message dispatched
   * @param _gasLimit Gas limit at which the messages will be executed on Optimism
   * @return bytes32 ID uniquely identifying the `messages`
   */
  function _dispatchMessageBatch(
    uint256 _toChainId,
    MessageLib.Message[] calldata _messages,
    uint32 _gasLimit
  ) internal returns (bytes32) {
    address _executorAddress = _getMessageExecutorAddress(_toChainId);
    _checkExecutor(_executorAddress);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageBatchId(_nonce, msg.sender, _messages);

    _sendMessage(
      _executorAddress,
      MessageLib.encodeMessageBatch(_messages, _messageId, block.chainid, msg.sender),
      _gasLimit
    );

    emit MessageBatchDispatched(_messageId, msg.sender, _toChainId, _messages);

    return _messageId;
  }

  /**
   * @notice Dispatch message to Optimism chain.
   * @param _executor Address of the executor contract on the Optimism chain
   * @param _message Message dispatched
   * @param _gasLimit Gas limit at which the message will be executed on Optimism
   */
  function _sendMessage(address _executor, bytes memory _message, uint32 _gasLimit) internal {
    crossDomainMessenger.sendMessage(_executor, _message, _gasLimit);
  }
}

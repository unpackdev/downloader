// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ExecutorAware.sol";
import "./ExecutorParserLib.sol";

/* ============ Custom Errors ============ */

/// @notice Thrown when the originChainId passed to the constructor is zero.
error OriginChainIdZero();

/// @notice Thrown when the Owner address passed to the constructor is zero address.
error OwnerZeroAddress();

/// @notice Thrown when the message was dispatched from an unsupported chain ID.
error OriginChainIdUnsupported(uint256 fromChainId);

/// @notice Thrown when the message was not executed by the executor.
error LocalSenderNotExecutor(address sender);

/// @notice Thrown when the message was not executed by the pending executor.
error LocalSenderNotPendingExecutor(address sender);

/// @notice Thrown when the message was not dispatched by the Owner on the origin chain.
error OriginSenderNotOwner(address sender);

/// @notice Thrown when the message was not dispatched by the pending owner on the origin chain.
error OriginSenderNotPendingOwner(address sender);

/// @notice Thrown when the call to the target contract failed.
error CallFailed(bytes returnData);

/// @title RemoteOwner
/// @author G9 Software Inc.
/// @notice RemoteOwner allows a contract on one chain to control a contract on another chain.
contract RemoteOwner is ExecutorAware {

  /* ============ Events ============ */

  /**
    * @dev Emitted when `_pendingOwner` has been changed.
    * @param pendingOwner new `_pendingOwner` address.
    */
  event OwnershipOffered(address indexed pendingOwner);

  /**
    * @dev Emitted when `_owner` has been changed.
    * @param previousOwner previous `_owner` address.
    * @param newOwner new `_owner` address.
    */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
    * @dev Emitted when `_pendingExecutor` has been declared by the owner.
    * @param pendingTrustedExecutor the pending trusted executor address.
    */
  event PendingExecutorPermissionTransfer(address indexed pendingTrustedExecutor);

  /**
   * @notice Emitted when ether is received to this contract via the `receive` function.
   * @param from The sender of the ether
   * @param value The value received
   */
  event Received(address indexed from, uint256 value);

  /* ============ Variables ============ */

  /// @notice ID of the origin chain that dispatches the auction auction results and random number.
  uint256 internal immutable _originChainId;

  /// @notice Address of the Owner on the origin chain that dispatches the auction results and random number.
  address private _owner;

  /// @notice Address of the new pending owner.
  address private _pendingOwner;

  /// @notice Address of the new pending trusted executor.
  address private _pendingExecutor;

  /* ============ Constructor ============ */

  /**
   * @notice ownerReceiver constructor.
   */
  constructor(
    uint256 originChainId_,
    address executor_,
    address __owner
  ) ExecutorAware(executor_) {
    if (__owner == address(0)) revert OwnerZeroAddress();
    if (originChainId_ == 0) revert OriginChainIdZero();
    _originChainId = originChainId_;
    _setOwner(__owner);
  }

  /* ============ Receive Ether Function ============ */

  /// @dev Emits a `Received` event
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /* ============ External Functions ============ */

  /**
   * @notice Executes a call on the target contract. Can only be called by the owner from the origin chain.
   * @param target The address to call
   * @param value Any eth value to pass along with the call
   * @param data The calldata
   * @return The return data of the call
   */
  function execute(address target, uint256 value, bytes calldata data) external onlyExecutorAndOriginChain onlyOwner returns (bytes memory) {
    (bool success, bytes memory returnData) = target.call{ value: value }(data);
    if (!success) revert CallFailed(returnData);
    assembly {
      return (add(returnData, 0x20), mload(returnData))
    }
  }

  /**
    * @notice Renounce ownership of the contract.
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
  function renounceOwnership() external virtual onlyExecutorAndOriginChain onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @notice Transfer ownership to another origin chain account
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) external onlyExecutorAndOriginChain onlyOwner {
    if (_newOwner == address(0)) revert OwnerZeroAddress();
    _pendingOwner = _newOwner;
    emit OwnershipOffered(_newOwner);
  }

  /**
  * @notice Allows the `_pendingOwner` address to finalize the transfer.
  * @dev This function is only callable by the `_pendingOwner`.
  */
  function claimOwnership() external onlyExecutorAndOriginChain onlyPendingOwner {
    _setOwner(_pendingOwner);
    delete _pendingOwner;
  }

  /**
   * @notice Transfers the executor permission to a new address.
   * @dev The owner must successfully call `claimExecutorPermission` through the new executor
   * to complete the transfer.
   * @param _executor Address of the new executor
   */
  function transferExecutorPermission(address _executor) external onlyExecutorAndOriginChain onlyOwner {
    if (_executor == address(0)) revert ExecutorZeroAddress();
    _pendingExecutor = _executor;
    emit PendingExecutorPermissionTransfer(_executor);
  }

  /**
   * @notice Activates the pending executor.
   * @dev This can only be called by the owner through the pending executor.
   */
  function claimExecutorPermission() external onlyPendingExecutorAndOriginChain onlyOwner {
    _setTrustedExecutor(_pendingExecutor);
    delete _pendingExecutor;
  }

  /* ============ Getters ============ */

  /**
   * @notice Get the ID of the origin chain.
   * @return ID of the origin chain
   */
  function originChainId() external view returns (uint256) {
    return _originChainId;
  }

  /**
   * @notice The owner address. This address is on the origin chain.
   * @return The owner address
   */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
    * @notice Gets current `_pendingOwner`.
    * @return Current `_pendingOwner` address.
    */
  function pendingOwner() external view virtual returns (address) {
    return _pendingOwner;
  }

  /**
    * @notice Gets current `_pendingExecutor`.
    * @return Current `_pendingExecutor` address.
    */
  function pendingTrustedExecutor() external view virtual returns (address) {
    return _pendingExecutor;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Sets the owner of the contract.
   * @param _newOwner Address of the new owner
   */
  function _setOwner(address _newOwner) internal {
    address _oldOwner = _owner;
    _owner = _newOwner;

    emit OwnershipTransferred(_oldOwner, _newOwner);
  }

  /**
   * @notice Asserts that the caller is the 5164 executor, and that the origin chain id is correct.
   */
  modifier onlyExecutorAndOriginChain() {
    if (!isTrustedExecutor(msg.sender)) revert LocalSenderNotExecutor(msg.sender);
    if (ExecutorParserLib.fromChainId() != _originChainId) revert OriginChainIdUnsupported(ExecutorParserLib.fromChainId());
    _;
  }

  /**
   * @notice Asserts that the caller is the pending 5164 executor, and that the origin chain id is correct.
   */
  modifier onlyPendingExecutorAndOriginChain() {
    if (msg.sender != _pendingExecutor) revert LocalSenderNotPendingExecutor(msg.sender);
    if (ExecutorParserLib.fromChainId() != _originChainId) revert OriginChainIdUnsupported(ExecutorParserLib.fromChainId());
    _;
  }

  /**
   * @notice Asserts that the 5164 sender matches the current owner
   */
  modifier onlyOwner() {
    if (ExecutorParserLib.msgSender() != address(_owner)) revert OriginSenderNotOwner(ExecutorParserLib.msgSender());
    _;
  }

  /**
   * @notice Asserts that the 5164 sender matches the pending owner
   */
  modifier onlyPendingOwner() {
    if (ExecutorParserLib.msgSender() != address(_pendingOwner)) revert OriginSenderNotPendingOwner(ExecutorParserLib.msgSender());
    _;
  }
}

pragma solidity ^0.8.16;

// Right now this is copy/pasted from the contracts package. We need to do this because we don't
// currently copy the contracts into the root of the contracts package in the correct way until
// we bundle the contracts package for publication. As a result, we can't properly use the
// package the way we want to from inside the monorepo (yet). Needs to be fixed as part of a
// separate pull request.

interface ICrossDomainMessenger {
  /**********
   * Events *
   **********/

  event SentMessage(
    address indexed target,
    address sender,
    bytes message,
    uint256 messageNonce,
    uint256 gasLimit
  );
  event RelayedMessage(bytes32 indexed msgHash);
  event FailedRelayedMessage(bytes32 indexed msgHash);

  /*************
   * Variables *
   *************/

  function xDomainMessageSender() external view returns (address);

  function messageNonce() external view returns (uint256);

  /********************
   * Public Functions *
   ********************/

  /**
   * Sends a cross domain message to the target messenger.
   * @param _target Target contract address.
   * @param _message Message to send to the target.
   * @param _gasLimit Gas limit for the provided message.
   */
  function sendMessage(address _target, bytes calldata _message, uint32 _gasLimit) external;

  /// @notice Relays a message that was sent by the other CrossDomainMessenger contract. Can only
  ///         be executed via cross-chain call from the other messenger OR if the message was
  ///         already received once and is currently being replayed.
  /// @param _nonce       Nonce of the message being relayed.
  /// @param _sender      Address of the user who sent the message.
  /// @param _target      Address that the message is targeted at.
  /// @param _value       ETH value to send with the message.
  /// @param _minGasLimit Minimum amount of gas that the message can be executed with.
  /// @param _message     Message to send to the target.
  function relayMessage(
    uint256 _nonce,
    address _sender,
    address _target,
    uint256 _value,
    uint256 _minGasLimit,
    bytes calldata _message
  ) external payable;
}

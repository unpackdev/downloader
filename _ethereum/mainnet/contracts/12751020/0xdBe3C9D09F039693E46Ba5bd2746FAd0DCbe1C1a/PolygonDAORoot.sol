// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./FxBaseRootTunnel.sol";

/// @title PolygonDAORoot
/// @author Alex T
/// @notice Root chain side of a Polygon data bridge meant to execute commands on the child chain
/// @dev This can be used to forward commands given by the DAO to be executed on the child chain
contract PolygonDAORoot is FxBaseRootTunnel, Ownable {
    bytes public latestData;

    /// @notice Logs a call being forwarded to the child chain
    /// @dev Emitted when callOnChild is called
    /// @param caller Address that called callOnChild
    /// @param target Target of call on the child chain
    /// @param value Value to transfer on execution
    /// @param sig Signature of function that will be called
    event CallOnChild(address indexed caller, address target, uint256 value, bytes4 sig);

    /// @notice PolygonDAORoot constructor
    /// @dev calls FxBaseRootTunnel(_checkpointManager, _fxRoot) 
    /// @param _checkpointManager Address of RootChainProxy from https://github.com/maticnetwork/static/tree/master/network
    /// @param _fxRoot Address of FxStateRootTunnel from https://docs.matic.network/docs/develop/l1-l2-communication/state-transfer/
    constructor(address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
    }

    /// @notice Used to receive message from child chain
    /// @dev Not currently used
    /// @param _data Data received from child chain
    function _processMessageFromChild(bytes memory _data) internal override {
        latestData = _data;
    }

    /// @notice Sends a payload to be executed on the child chain
    /// @dev Payload needs to be encoded like abi.encode(_target, _value, _data)
    /// @param _message payload to execute on the child chain
    function sendMessageToChild(bytes memory _message) public onlyOwner {
        _sendMessageToChild(_message);
    }

    /// @notice Encodes and sends a payload to be executed on the child chain
    /// @dev This is what you will use most of the time. Emits CallOnChild
    /// @param _target Address on child chain against which to execute the tx
    /// @param _value Value to transfer
    /// @param _data Calldata for the child tx
    function callOnChild(address _target, uint256 _value, bytes memory _data) public onlyOwner {
        require(_target != address(0), "PolygonDAORoot: a valid target address must be provided");

        bytes memory message = abi.encode(_target, _value, _data);
        sendMessageToChild(message);

        emit CallOnChild(msg.sender, _target, _value, bytes4(_data));
    }
}

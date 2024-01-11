// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";

import "./Adminable.sol";
import "./IMessageHandler.sol";
import "./IRootTunnel.sol";

contract RootTunnel is IRootTunnel, FxBaseRootTunnel, Adminable {

    IMessageHandler public messageHandler;

    constructor(
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        _pause();
    }

    function setMessageHandler(address _messageHandlerAddress) external onlyAdminOrOwner {
        require(_messageHandlerAddress != address(0), "invalid message handler");
        messageHandler = IMessageHandler(_messageHandlerAddress);
    }

    function sendMessageToChild(bytes calldata _data) external override onlyAdminOrOwner {
        require(address(messageHandler) != address(0), "No message handler set");
        _sendMessageToChild(_data);
    }

    function _processMessageFromChild(bytes memory data) internal override {
        require(address(messageHandler) != address(0), "No message handler set");
        messageHandler.handleMessage(data);
    }

}
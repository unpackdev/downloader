// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./WmbRetryableApp.sol";

contract MockRetryableApp is WmbRetryableApp {
    
    struct MessageData {
        bytes32 messageId;
        bytes data;
        uint256 fromChainId;
        address from;
    }

    mapping(bytes32 => MessageData) public receivedMessages;
    mapping(uint => bytes32) public sentMessages;
    uint public sentCount;

    constructor(address admin, address _wmbGateway) WmbApp() {
        initialize(admin, _wmbGateway);
    }

    function burnGas() public pure {
        uint256 a;
        for (uint256 i = 0; i < 2000; i++) {
            a = i * i;
        }
        for (uint256 i = 0; i < 2000; i++) {
            a = i + i;
        }
    }

    function _wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address from
    ) internal override {
        receivedMessages[messageId] = MessageData(messageId, data, fromChainId, from);
        burnGas();
    }

    function dispatchMessage(
        uint256 toChainId,
        address to,
        bytes calldata data
    ) public payable {
        bytes32 messageId = _dispatchMessage(toChainId, to, data, msg.value);
        sentMessages[sentCount] = messageId;
        sentCount++;
    }

    function dispatchMessageBatch(
        uint256 toChainId,
        Message[] calldata messages
    ) public payable {
        bytes32 messageId = _dispatchMessageBatch(toChainId, messages, msg.value);
        sentMessages[sentCount] = messageId;
        sentCount++;
    }

    function dropMessage(bytes32 messageId) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WmbApp: must have admin role to set trusted remotes");
        _dropMessage(messageId);
    }
}

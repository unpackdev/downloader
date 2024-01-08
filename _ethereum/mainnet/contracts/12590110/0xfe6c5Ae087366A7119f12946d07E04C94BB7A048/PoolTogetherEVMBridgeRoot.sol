// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.8.0;
pragma experimental ABIEncoderV2;

import "./MultiSend.sol";

import "./FxBaseRootTunnel.sol";
import "./Ownable.sol";

/// @title PoolTogetherEVMBridgeRoot lives on the parent chain (e.g. eth mainnet) and sends messages to a child chain
contract  PoolTogetherEVMBridgeRoot is Ownable, FxBaseRootTunnel {

    /// @notice Emitted when a message is sent to the child chain
    event SentMessagesToChild(Message[] data);

    /// @notice Structure of a message to be sent to the child chain
    struct Message {
        uint8 callType;
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Contract constructor
    /// @param _owner Owner of this contract
    /// @param _checkpointManager Address of the checkpoint manager
    /// @param _fxRoot Address of the fxRoot for the chain
    constructor(address _owner, address _checkpointManager, address _fxRoot) public 
        Ownable() 
        FxBaseRootTunnel(_checkpointManager, _fxRoot) 
    {
        
        transferOwnership(_owner);
    }

    /// @notice Structure of a message to be sent to the child chain
    /// @param messages Array of Message's that will be encoded and sent to the child chain
    function execute(Message[] calldata messages) external onlyOwner returns (bool) {
    
        bytes memory encodedMessages;
        
        for(uint i =0; i < messages.length; i++){
            encodedMessages = abi.encodePacked(
                    encodedMessages,
                    messages[i].callType,
                    messages[i].to,
                    messages[i].value,
                    messages[i].data.length,
                    messages[i].data
            ); 
        }
        _sendMessageToChild(encodedMessages);

        emit SentMessagesToChild(messages);
        return true;
    }

    /// @notice Function called as callback from child network
    /// @param message The message from the child chain
    function _processMessageFromChild(bytes memory message) internal override {
        // no-op
    }

}
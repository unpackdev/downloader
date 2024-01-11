// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./FxBaseRootTunnel.sol";

import "./IToken.sol";

contract RootShadowManager is FxBaseRootTunnel, Ownable {

    bytes32 public constant SYNC_SHADOW = keccak256("SYNC_SHADOW");

    bytes public latestData;

    IToken public rootToken;

    uint256 public countShadowSyncAttempts = 0;
    uint256 public countMessageSentAttempts = 0;
    address public lastAttemptedAddress;
    address public lastSender;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        IToken _rootToken
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootToken = _rootToken;

    }

    // TODO: shadow wallet address L2?
    function syncShadow(uint256 tokenId, address shadow) external
    {
        countShadowSyncAttempts += 1;
        lastSender = msg.sender;

        // Sender must own token to claim Shadow.
        address rootTokenOwner = rootToken.ownerOf(tokenId);

        lastAttemptedAddress = rootTokenOwner;

        require(
            msg.sender == rootTokenOwner, "Only root token owner can sync Shadow"
        );

        bytes memory message = abi.encode(SYNC_SHADOW, abi.encode(msg.sender, shadow, tokenId));
        _sendMessageToChild(message);

        countMessageSentAttempts += 1;
    }

    function setRootToken(IToken _rootToken) external onlyOwner {
        rootToken = _rootToken;
    }


    function _processMessageFromChild(bytes memory data) internal override {
        latestData = data;
    }

}
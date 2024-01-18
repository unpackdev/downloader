// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBridge {
    enum BridgePhase {
        PUBLIC_PHASE,
        WHITELIST_PHASE
    }

    struct BridgePosition {
        uint256 positionId;
        uint256 positionAmount;
    }

    event BridgeOngoingPhase(BridgePhase phase);
    event BridgeTotalDailyLimit(uint256 limit);
    event BridgeOperatorDailyLimit(uint256 limit);
    event BridgeToken(address indexed token);
    event BridgeSigner(address indexed signer);
    event BridgeValidator(address indexed validator);
    event BridgeWhitelist(bytes32 indexed whitelist);
    event BridgeBlacklist(address indexed operator, bool active);
    event BridgeDeposit(address indexed user, uint256 chainId, uint256 amount);
    event BridgeWithdraw(address indexed user, uint256 chainId, uint256 amount);
}

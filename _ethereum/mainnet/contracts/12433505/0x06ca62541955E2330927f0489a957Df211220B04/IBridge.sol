// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface IBridge {
    function isRelay(address candidate) external view returns (bool);
    function countRelaysSignatures(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external view returns(uint);

    struct BridgeConfiguration {
        uint16 nonce;
        uint16 bridgeUpdateRequiredConfirmations;
    }

    struct BridgeRelay {
        uint16 nonce;
        address account;
        bool action;
    }

    function getConfiguration() external view returns (BridgeConfiguration memory);
}

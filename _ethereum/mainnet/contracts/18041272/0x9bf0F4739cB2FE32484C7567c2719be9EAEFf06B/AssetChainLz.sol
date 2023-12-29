// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "./CrossChainFunctions.sol";
import "./IPortal.sol";
import "./IAssetChainManager.sol";
import "./NonblockingLzApp.sol";

/**
 * Deploys on the asset chain and handles sending/receiving messages using LayerZero
 */
contract AssetChainLz is NonblockingLzApp, CrossChainFunctions {
    address public manager;
    uint16 public immutable processingChainId;

    constructor(address _admin, address _lzEndpoint, uint16 _processingChainId) NonblockingLzApp(_lzEndpoint) {
        // We expect this contract to be deployed through the asset chain manager
        manager = msg.sender;
        _transferOwnership(_admin);
        processingChainId = _processingChainId;
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64, /*_nonce*/
        bytes memory _payload
    )
        internal
        override
    {
        if (_srcChainId != processingChainId) revert();
        CrossChainMessage memory message = abi.decode(_payload, (CrossChainMessage));
        if (message.instruction == WRITE_OBLIGATIONS) {
            IPortal.Obligation[] memory obligations = abi.decode(message.payload, (IPortal.Obligation[]));
            IPortal(IAssetChainManager(manager).portal()).writeObligations(obligations);
        } else if (message.instruction == REJECT_DEPOSITS) {
            bytes32[] memory depositHashes = abi.decode(message.payload, (bytes32[]));
            IPortal(IAssetChainManager(manager).portal()).rejectDeposits(depositHashes);
        }
    }
}

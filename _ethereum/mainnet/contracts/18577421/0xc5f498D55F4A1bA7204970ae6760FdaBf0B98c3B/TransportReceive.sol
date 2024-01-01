// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./VaultChildProxy.sol";
import "./VaultChild.sol";
import "./VaultParent.sol";
import "./IVaultRiskProfile.sol";

import "./ILayerZeroReceiver.sol";

import "./TransportBase.sol";
import "./TransportSend.sol";

import "./Call.sol";

abstract contract TransportReceive is TransportSend, ILayerZeroReceiver {
    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    function lzReceive(
        uint16 srcChainId,
        bytes calldata srcAddress,
        uint64, // nonce
        bytes calldata payload
    ) external {
        require(
            msg.sender == address(_lzEndpoint()),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = _trustedRemoteLookup(srcChainId);
        require(
            srcAddress.length == trustedRemote.length &&
                keccak256(srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );
        Call._call(address(this), payload);
    }

    ///
    /// Message received callbacks - public onlyThis
    ///

    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgeApprovalCancellation(request.requester);
    }

    function bridgeApproval(
        BridgeApprovalRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.approvedVault)).receiveBridgeApproval();
    }

    function withdraw(WithdrawRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveWithdrawRequest(
            request.tokenId,
            request.withdrawer,
            request.portion
        );

        sendWithdrawComplete(
            ITransport.WithdrawComplete({
                parentChainId: request.parentChainId,
                parentVault: request.parentVault
            })
        );
    }

    function withdrawComplete(WithdrawComplete memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveWithdrawComplete();
    }

    function getVaultValue(ValueUpdateRequest memory request) public onlyThis {
        uint256 gasRemaining = gasleft();
        try
            // This would fail if for instance chainlink feed is stale
            // If a callback fails the message is deemed failed to deliver by LZ and is queued
            // Retrying it will likely not result in a better outcome and will block message delivery
            // For other vaults
            VaultChild(payable(request.child.vault)).getVaultValue()
        returns (uint _minValue, uint _maxValue, bool _hasHardDeprecatedAsset) {
            _sendValueUpdatedRequest(
                ValueUpdatedRequest({
                    parentChainId: request.parentChainId,
                    parentVault: request.parentVault,
                    child: request.child,
                    time: block.timestamp,
                    minValue: _minValue,
                    maxValue: _maxValue,
                    hasHardDepreactedAsset: _hasHardDeprecatedAsset
                })
            );
        } catch {
            // github.com/vertex-protocol/vertex-contracts
            // /blob/3258d58eb1e56ece0513b3efcc468cc09a7414c4/contracts/Endpoint.sol#L333
            // we need to differentiate between a revert and an out of gas
            // the expectation is that because 63/64 * gasRemaining is forwarded
            // we should be able to differentiate based on whether
            // gasleft() >= gasRemaining / 64. however, experimentally
            // even more gas can be remaining, and i don't have a clear
            // understanding as to why. as a result we just err on the
            // conservative side and provide two conservative
            // asserts that should cover all cases
            // As above in practice more than 1/64th of the gas is remaining
            // The code that executes after the try { // here } requires more than 100k gas anyway
            if (gasleft() <= 100_000 || gasleft() <= gasRemaining / 16) {
                // If we revert the message will fail to deliver and need to be retried
                // In the case of out of gas we want this message to be retried by our keeper
                revert('getVaultValue out of gas');
            }
        }
    }

    function updateVaultValue(
        ValueUpdatedRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildValue(
            request.child.chainId,
            request.minValue,
            request.maxValue,
            request.time,
            request.hasHardDepreactedAsset
        );
    }

    function createVaultChild(
        VaultChildCreationRequest memory request
    ) public onlyThis {
        address child = _deployChild(
            request.parentChainId,
            request.parentVault,
            request.manager,
            request.riskProfile,
            request.children
        );
        _sendChildCreatedRequest(
            ChildCreatedRequest({
                parentVault: request.parentVault,
                parentChainId: request.parentChainId,
                newChild: ChildVault({
                    chainId: _registry().chainId(),
                    vault: child
                })
            })
        );
    }

    function childCreated(ChildCreatedRequest memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildCreated(
            request.newChild.chainId,
            request.newChild.vault
        );
    }

    function addSibling(AddVaultSiblingRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveAddSibling(
            request.newSibling.chainId,
            request.newSibling.vault
        );
    }

    function changeManager(
        ChangeManagerRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveManagerChange(
            request.newManager
        );
    }

    function sgBridgedAssetReceived(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgedAssetAcknowledgement(request.receivingChainId);
    }

    /// Deploy Child

    function _deployChild(
        uint16 parentChainId,
        address parentVault,
        address manager,
        VaultRiskProfile riskProfile,
        ITransport.ChildVault[] memory children
    ) internal whenNotPaused returns (address deployment) {
        deployment = address(
            new VaultChildProxy(_registry().childVaultDiamond())
        );
        VaultChild(payable(deployment)).initialize(
            parentChainId,
            parentVault,
            manager,
            riskProfile,
            _registry(),
            children
        );
        _registry().addVaultChild(deployment);

        emit VaultChildCreated(deployment);
        _registry().emitEvent();
    }
}

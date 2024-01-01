// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./ITransport.sol";
import "./IVaultRiskProfile.sol";
import "./TransportBase.sol";
import "./ITransport.sol";

abstract contract TransportSend is TransportBase {
    modifier onlyVaultParent() {
        require(_registry().isVaultParent(msg.sender), 'not parent vault');
        _;
    }

    modifier onlyVaultChild() {
        require(_registry().isVaultChild(msg.sender), 'not child vault');
        _;
    }

    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external view returns (uint256 sendFee, bytes memory adapterParams) {
        return _getLzFee(gasFunctionType, dstChainId);
    }

    ///
    /// Message senders
    ///
    // solhint-disable-next-line ordering
    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.changeManager.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.withdraw.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.withdrawRequiresReturnMessage
            )
        );
    }

    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.approvedChainId,
            abi.encodeWithSelector(ITransport.bridgeApproval.selector, request),
            msg.value,
            _getAdapterParams(
                request.approvedChainId,
                GasFunctionType.sendBridgeApprovalNoReturnMessage
            )
        );
    }

    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable onlyVaultChild whenNotPaused {
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.bridgeApprovalCancellation.selector,
                request
            ),
            msg.value,
            _getAdapterParams(
                request.parentChainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable onlyVault whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.getVaultValue.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.getVaultValueRequiresReturnMessage
            )
        );
    }

    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        require(
            _getTrustedRemoteDestination(request.newChainId) != address(0),
            'unsupported destination chain'
        );
        _send(
            request.newChainId,
            abi.encodeWithSelector(
                ITransport.createVaultChild.selector,
                request
            ),
            msg.value,
            _getAdapterParams(
                request.newChainId,
                GasFunctionType.createChildRequiresReturnMessage
            )
        );
    }

    /// Return/Reply message senders

    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external onlyVaultParent whenNotPaused {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.child.chainId
        );
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.addSibling.selector, request),
            fee,
            adapterParams
        );
    }

    function sendWithdrawComplete(WithdrawComplete memory request) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.withdrawComplete.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendValueUpdatedRequest(
        ValueUpdatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.updateVaultValue.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendSGBridgedAssetAcknowledment(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.sgBridgedAssetReceived.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendChildCreatedRequest(
        ChildCreatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.childCreatedNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(ITransport.childCreated.selector, request),
            fee,
            adapterParams
        );
    }

    /// Internal

    function _send(
        uint16 dstChainId,
        bytes memory payload,
        uint sendFee,
        bytes memory adapterParams
    ) internal {
        require(
            address(this).balance >= sendFee,
            'Transport: insufficient balance'
        );
        _lzEndpoint().send{ value: sendFee }(
            dstChainId,
            _trustedRemoteLookup(dstChainId),
            payload,
            payable(address(this)),
            payable(address(this)),
            adapterParams
        );
    }

    function _getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) internal view returns (uint256 sendFee, bytes memory adapterParams) {
        // We just use the largest message for now
        ChildVault memory childVault = ChildVault({
            chainId: 0,
            vault: address(0)
        });
        ChildVault[] memory childVaults = new ChildVault[](2);
        childVaults[0] = childVault;
        childVaults[1] = childVault;

        VaultChildCreationRequest memory request = VaultChildCreationRequest({
            parentVault: address(0),
            parentChainId: 0,
            newChainId: 0,
            manager: address(0),
            riskProfile: VaultRiskProfile.low,
            children: childVaults
        });

        bytes memory payload = abi.encodeWithSelector(
            this.sendVaultChildCreationRequest.selector,
            request
        );

        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        adapterParams = _getAdapterParams(dstChainId, gasFunctionType);

        (sendFee, ) = _lzEndpoint().estimateFees(
            dstChainId,
            dstAddr,
            payload,
            false,
            adapterParams
        );
    }

    function _requiresReturnMessage(
        GasFunctionType gasFunctionType
    ) internal pure returns (bool) {
        if (
            gasFunctionType == GasFunctionType.standardNoReturnMessage ||
            gasFunctionType ==
            GasFunctionType.sendBridgeApprovalNoReturnMessage ||
            gasFunctionType == GasFunctionType.childCreatedNoReturnMessage
        ) {
            return false;
        }
        return true;
    }

    function _getAdapterParams(
        uint16 dstChainId,
        GasFunctionType gasFunctionType
    ) internal view returns (bytes memory) {
        bool requiresReturnMessage = _requiresReturnMessage(gasFunctionType);
        return
            abi.encodePacked(
                uint16(2),
                // The amount of gas the destination consumes when it receives the messaage
                _destinationGasUsage(dstChainId, gasFunctionType),
                // Amount to Airdrop to the remote transport
                requiresReturnMessage ? _returnMessageCost(dstChainId) : 0,
                // Gas Receiver
                requiresReturnMessage
                    ? _getTrustedRemoteDestination(dstChainId)
                    : address(0)
            );
    }
}

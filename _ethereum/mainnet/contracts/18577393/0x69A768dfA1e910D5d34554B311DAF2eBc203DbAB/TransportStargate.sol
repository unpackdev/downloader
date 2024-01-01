// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./VaultBaseExternal.sol";

import "./IStargateRouter.sol";
import "./IStargateReceiver.sol";

import "./TransportReceive.sol";
import "./ITransport.sol";

abstract contract TransportStargate is TransportReceive, IStargateReceiver {
    using SafeERC20 for IERC20;

    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    // Does not currently support weth
    function sgReceive(
        uint16, // _srcChainId,
        bytes memory, // _srcAddress
        uint, // _nonce
        address _token,
        uint amountLD,
        bytes memory _payload
    ) external override {
        require(
            msg.sender == address(_stargateRouter()),
            'only stargate router can call sgReceive!'
        );
        SGReceivePayload memory payload = abi.decode(
            _payload,
            (SGReceivePayload)
        );
        // send transfer _token/amountLD to _toAddr
        IERC20(_token).transfer(payload.dstVault, amountLD);
        VaultBaseExternal(payable(payload.dstVault)).receiveBridgedAsset(
            _token
        );
        // Already on the parent chain - no need to send a message
        if (_registry().chainId() == payload.parentChainId) {
            this.sgBridgedAssetReceived(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: payload.parentChainId
                })
            );
        } else {
            _sendSGBridgedAssetAcknowledment(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: _registry().chainId()
                })
            );
        }
    }

    function bridgeAsset(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstVault, // the address to send the destination tokens to
        uint16 parentChainId,
        address parentVault,
        address bridgeToken, // the address of the native ERC20 to swap() - *must* be the token for the poolId
        uint amount,
        uint minAmountOut
    ) external payable onlyVault whenNotPaused {
        require(amount > 0, 'error: swap() requires amount > 0');
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        uint srcPoolId = _stargateAssetToSrcPoolId(bridgeToken);
        uint dstPoolId = _stargateAssetToDstPoolId(dstChainId, bridgeToken);
        require(srcPoolId != 0, 'no srcPoolId');
        require(dstPoolId != 0, 'no dstPoolId');

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        IERC20(bridgeToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(bridgeToken).safeApprove(address(_stargateRouter()), amount);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(_stargateRouter()).swap{ value: msg.value }(
            dstChainId, // the destination chain id
            srcPoolId, // the source Stargate poolId
            dstPoolId, // the destination Stargate poolId
            payable(address(this)), // refund adddress. if msg.sender pays too much gas, return extra eth
            amount, // total tokens to send to destination chain
            minAmountOut, // min amount allowed out
            lzTxObj, // default lzTxObj
            abi.encodePacked(dstAddr), // destination address, the sgReceive() implementer
            data // bytes payload
        );
    }

    function getBridgeAssetQuote(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstVault, // the address to send the destination tokens to
        uint16 parentChainId,
        address parentVault
    ) external view returns (uint fee) {
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        // Mock payload for quote
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        (fee, ) = IStargateRouter(_stargateRouter()).quoteLayerZeroFee(
            dstChainId,
            1, // function type: see Stargate Bridge.sol for all types
            abi.encodePacked(dstAddr), // destination contract. it must implement sgReceive()
            data,
            lzTxObj
        );
    }

    function _getStargateTxObj(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstTransportAddress, // the address to send the destination tokens to
        uint16 parentChainId
    ) internal view returns (IStargateRouter.lzTxObj memory lzTxObj) {
        uint DST_GAS = _destinationGasUsage(
            dstChainId,
            GasFunctionType.sgReceiveRequiresReturnMessage
        );
        return
            IStargateRouter.lzTxObj({
                ///
                /// This needs to be enough for the sgReceive to execute successfully on the remote
                /// We will need to accurately access how much the Transport.sgReceive function needs
                ///
                dstGasForCall: DST_GAS,
                // Once the receiving vault receives the bridge the transport sends a message to the parent
                // If the dstChain is the parentChain no return message is required
                dstNativeAmount: dstChainId == parentChainId
                    ? 0
                    : _returnMessageCost(dstChainId),
                dstNativeAddr: abi.encodePacked(dstTransportAddress)
            });
    }
}

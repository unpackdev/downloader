// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoCBridge.sol";

contract RangoCBridgeProxy is BaseProxyContract {

    //keccak256("exchange.rango.cbridge.proxy")
    bytes32 internal constant RANGO_CBRIDGE_PROXY_NAMESPACE = hex"e9cf4febccbfad5ef15964f91cb6c48fe594747e386f28fc2b067ddf16f1ed5d";

    struct CBridgeProxyStorage {
        address rangoCBridgeAddress;
    }

    function updateRangoCBridgeAddress(address _address) external onlyOwner {
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();
        cbridgeProxyStorage.rangoCBridgeAddress = _address;
    }

    function cBridgeSend(
        SwapRequest memory request,
        Call[] calldata calls,

        // cbridge params
        address _receiver,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable whenNotPaused nonReentrant {
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();
        require(cbridgeProxyStorage.rangoCBridgeAddress != NULL_ADDRESS, 'cBridge address in Rango contract not set');

        bool isNative = request.fromToken == NULL_ADDRESS;
        uint minimumRequiredValue = isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover sgnFee + input amount');

        (, uint out) = onChainSwapsInternal(request, calls);
        approve(request.toToken, cbridgeProxyStorage.rangoCBridgeAddress, out);

        IRangoCBridge(cbridgeProxyStorage.rangoCBridgeAddress)
            .send(_receiver, request.toToken, out, _dstChainId, _nonce, _maxSlippage);
    }

    function cBridgeIM(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage
    ) external payable whenNotPaused nonReentrant {
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();
        require(cbridgeProxyStorage.rangoCBridgeAddress != NULL_ADDRESS, 'cBridge address in Rango contract not set');

        bool isNative = request.fromToken == NULL_ADDRESS;
        uint minimumRequiredValue = (isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0) + _sgnFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover sgnFee + input amount');

        (, uint out) = onChainSwapsInternal(request, calls);
        approve(request.toToken, cbridgeProxyStorage.rangoCBridgeAddress, out);

        IRangoCBridge(cbridgeProxyStorage.rangoCBridgeAddress).cBridgeIM{value: _sgnFee}(
            request.toToken,
            out,
            _receiverContract,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _sgnFee,
            imMessage
        );
    }

    function getCBridgeProxyStorage() internal pure returns (CBridgeProxyStorage storage s) {
        bytes32 namespace = RANGO_CBRIDGE_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
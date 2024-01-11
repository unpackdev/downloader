// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoMultichain.sol";

contract RangoMultichainProxy is BaseProxyContract {

    //keccak256("exchange.rango.multichain.proxy")
    bytes32 internal constant RANGO_MULTICHAIN_PROXY_NAMESPACE = hex"ed7d91da7fb046892c2413e11ecc409c17b784b916ff0fd3fa2d512c567da864";

    struct MultichainProxyStorage {
        address rangoMultichainAddress;
    }
    
    struct MultichainBridgeRequest {
        RangoMultichainModels.MultichainBridgeType _actionType;
        address _underlyingToken;
        address _multichainRouter;
        address _receiverAddress;
        uint _receiverChainID;
    }

    function updateRangoMultichainAddress(address _address) external onlyOwner {
        MultichainProxyStorage storage multichainProxyStorage = getMultichainProxyStorage();
        multichainProxyStorage.rangoMultichainAddress = _address;
    }

    function multichainBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        MultichainBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        MultichainProxyStorage storage multichainProxyStorage = getMultichainProxyStorage();
        require(multichainProxyStorage.rangoMultichainAddress != NULL_ADDRESS, 'Multichain address in Rango contract not set');

        bool isNative = request.fromToken == NULL_ADDRESS;
        uint minimumRequiredValue = isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, uint out) = onChainSwapsInternal(request, calls);
        if (request.toToken != NULL_ADDRESS)
            approve(request.toToken, multichainProxyStorage.rangoMultichainAddress, out);

        uint value = request.toToken == NULL_ADDRESS ? (out > 0 ? out : request.amountIn) : 0;

        IRangoMultichain(multichainProxyStorage.rangoMultichainAddress).multichainBridge{value: value}(
            bridgeRequest._actionType,
            request.toToken,
            bridgeRequest._underlyingToken,
            out,
            bridgeRequest._multichainRouter,
            bridgeRequest._receiverAddress,
            bridgeRequest._receiverChainID
        );
    }

    function getMultichainProxyStorage() internal pure returns (MultichainProxyStorage storage s) {
        bytes32 namespace = RANGO_MULTICHAIN_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
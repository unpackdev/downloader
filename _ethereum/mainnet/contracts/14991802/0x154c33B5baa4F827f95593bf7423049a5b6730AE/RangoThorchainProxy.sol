// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoThorchain.sol";

contract RangoThorchainProxy is BaseProxyContract {

    //keccak256("exchange.rango.thorchain.proxy")
    bytes32 internal constant RANGO_THORCHAIN_PROXY_NAMESPACE = hex"2d408556142e9c30601bb067c0631f1a23ffac1d1598afa3da595c26103e4966";

    struct ThorchainProxyStorage {
        address rangoThorchainAddress;
    }

    function updateRangoThorchainAddress(address _address) external onlyOwner {
        ThorchainProxyStorage storage thorchainProxyStorage = getThorchainProxyStorage();
        thorchainProxyStorage.rangoThorchainAddress = _address;
    }

    function swapInToThorchain(
        SwapRequest memory request,
        Call[] calldata calls,

        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        ThorchainProxyStorage storage thorchainProxyStorage = getThorchainProxyStorage();
        require(thorchainProxyStorage.rangoThorchainAddress != NULL_ADDRESS, 'Thorchain wrapper address in Rango contract not set');

        (, uint out) = onChainSwapsInternal(request, calls);
        uint value = 0;
        if (request.toToken != NULL_ADDRESS) {
            approve(request.toToken, thorchainProxyStorage.rangoThorchainAddress, out);
        } else {
            value = out;
        }

        IRangoThorchain(thorchainProxyStorage.rangoThorchainAddress).swapInToThorchain{value : value}(
            request.toToken,
            out,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );
    }

    function getThorchainProxyStorage() internal pure returns (ThorchainProxyStorage storage s) {
        bytes32 namespace = RANGO_THORCHAIN_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoMultichain.sol";

/// @title The functions that allow users to perform a MultichainOrg call with or without some arbitrary DEX calls
/// @author Uchiha Sasuke
/// @notice It contains functions to call MultichainOrg bridge
/// @dev This contract only handles the DEX part and calls RangoMultichain.sol functions via contact call to perform the bridiging step
contract RangoMultichainProxy is BaseProxyContract {

    /// @dev keccak256("exchange.rango.multichain.proxy")
    bytes32 internal constant RANGO_MULTICHAIN_PROXY_NAMESPACE = hex"ed7d91da7fb046892c2413e11ecc409c17b784b916ff0fd3fa2d512c567da864";

    struct MultichainProxyStorage {
        address rangoMultichainAddress;
    }

    /// @notice Notifies that the RangoMultichain.sol contract address is updated
    /// @param _oldAddress The previous deployed address
    /// @param _newAddress The new deployed address
    event RangoMultichainAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice The request object for MultichainOrg bridge call
    /// @param _actionType The type of bridge action which indicates the name of the function of MultichainOrg contract to be called
    /// @param _underlyingToken For _actionType = OUT_UNDERLYING, it's the address of the underlying token
    /// @param _multichainRouter Address of MultichainOrg contract on the current chain
    /// @param _receiverAddress The address of end-user on the destination
    /// @param _receiverChainID The network id of destination chain
    struct MultichainBridgeRequest {
        RangoMultichainModels.MultichainBridgeType _actionType;
        address _underlyingToken;
        address _multichainRouter;
        address _receiverAddress;
        uint _receiverChainID;
    }

    /// @notice Updates the address of deployed RangoMultichain.sol contract
    /// @param _address The address
    function updateRangoMultichainAddress(address _address) external onlyOwner {
        MultichainProxyStorage storage multichainProxyStorage = getMultichainProxyStorage();

        address oldAddress = multichainProxyStorage.rangoMultichainAddress;
        multichainProxyStorage.rangoMultichainAddress = _address;

        emit RangoMultichainAddressUpdated(oldAddress, _address);
    }

    /// @notice Executes a DEX (arbitrary) call + a MultichainOrg bridge call
    /// @dev The cbridge part is handled in the RangoMultichain.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
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

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getMultichainProxyStorage() internal pure returns (MultichainProxyStorage storage s) {
        bytes32 namespace = RANGO_MULTICHAIN_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
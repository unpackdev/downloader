// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoCBridge.sol";

/// @title The functions that allow users to perform a cbridge call with or without some arbitrary DEX calls
/// @author Uchiha Sasuke
/// @notice It contains functions to call cbridge.send for simple transfers or Celer IM for cross-chain messaging
/// @dev This contract only handles the DEX part and calls RangoCBridge.sol functions via contact call to perform the bridiging step
contract RangoCBridgeProxy is BaseProxyContract {

    /// @dev keccak256("exchange.rango.cbridge.proxy")
    bytes32 internal constant RANGO_CBRIDGE_PROXY_NAMESPACE = hex"e9cf4febccbfad5ef15964f91cb6c48fe594747e386f28fc2b067ddf16f1ed5d";

    struct CBridgeProxyStorage {
        address rangoCBridgeAddress;
    }

    /// @notice Notifies that the RangoCBridge.sol contract address is updated
    /// @param _oldAddress The previous deployed address
    /// @param _newAddress The new deployed address
    event RangoCBridgeAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Updates the address of deployed RangoCBridge.sol contract
    /// @param _address The address
    function updateRangoCBridgeAddress(address _address) external onlyOwner {
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();

        address oldAddress = cbridgeProxyStorage.rangoCBridgeAddress;
        cbridgeProxyStorage.rangoCBridgeAddress = _address;

        emit RangoCBridgeAddressUpdated(oldAddress, _address);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge send function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiver The receiver address in the destination chain
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @dev If this function is success, user will automatically receive the fund in the destination in his/her wallet (_receiver)
    /// @dev If bridge is out of liquidity somehow after submiting this transaction and success, user must sign a refund transaction which is not currently present here, will be supported soon
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
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount');

        (, uint out) = onChainSwapsInternal(request, calls);
        approve(request.toToken, cbridgeProxyStorage.rangoCBridgeAddress, out);

        IRangoCBridge(cbridgeProxyStorage.rangoCBridgeAddress)
            .send(_receiver, request.toToken, out, _dstChainId, _nonce, _maxSlippage);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge IM function
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiverContract Our RangoCbridge.sol contract in the destination chain that will handle the destination logic
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @param _sgnFee The fee amount (in native token) that cBridge IM charges for delivering the message
    /// @param imMessage Our custom interchain message that contains all the required info for the RangoCBridge.sol on the destination
    /// @dev The msg.value should at least be _sgnFee + (input + fee + affiliate) if input is native token
    /**
     * @dev Here is the overall flow for a cross-chain dApp that integrates Rango + cBridgeIM:
     * Example case: RangoSea is an imaginary cross-chain OpenSea that users can lock their NFT on BSC to get 100 BNB
     * and convert it to FTM to buy another NFT there, all in one TX.
     * RangoSea contract = RS
     * Rango contract = R
     *
     * 1. RangoSea server asks Rango for a quote of 100 BSC.BNB to Fantom.FTM and embeds the message (imMessage.dAppMessage) that should be received by RS on destination
     * 2. User signs sellNFTandBuyCrosschain on RS
     * 3. RS executes their own logic and locks the NFT, gets 100 BNB and calls R with the hex from step 1 (which is cBridgeIM function call)
     * 4. R on source chain does the required swap/bridge
     * 5. R on destination receives the message via Celer network (by calling RangoCBridge.executeMessageWithTransfer on dest) and does other Rango internal stuff on destination to have the final FTM
     * 6. R on dest sends fund to RS on dest and calls their handler function for message handling and passes imMessage.dAppMessage to it
     * 7. RS on destination has the money and the message it needs to buy the NFT on destination and if it is still available it will be purchased
     *
     * Failure scenarios:
     * If cBridge does not have enough liquidity later:
     * 1. Celer network will call (RangoCBridge on source chain).executeMessageWithTransferRefund function
     * 2. RangoCbridge will refund money to the RS contract on source and ask it to handle refund to their own users
     *
     * If something on the destination fails:
     * 1. Celer network will call (RangoCBridge on dest chain).executeMessageWithTransferFallback function
     * 2. R on dest sends fund to RS on dest with refund reason, again RS should send it to your user if you like
     *
     * Hint: The dAppMessage part is arbitrary, if it's not set. The scenario is the same as above but without RS being in. In this case Rango will refund to the end-user.
     * Here is the celer IM docs: https://im-docs.celer.network/
     */
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


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getCBridgeProxyStorage() internal pure returns (CBridgeProxyStorage storage s) {
        bytes32 namespace = RANGO_CBRIDGE_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
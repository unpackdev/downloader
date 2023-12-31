// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./QuoterStorage.sol";
import "./IStargateBridge.sol";
import "./CrossChainLib.sol";

error AddressIsNull();
error NotAvailableOnThisChain();

/**
 * @title Quoter contract
 */
contract Quoter is Initializable, QuoterStorageV1 {
    string public constant VERSION = "1.3.0";

    /**
     * @dev LayerZero adapter param version
     * See more: https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters
     */
    uint16 public constant LZ_ADAPTER_PARAMS_VERSION = 2;

    /**
     * @dev Stargate swap function type
     * See more: https://stargateprotocol.gitbook.io/stargate/developers/function-types
     */
    uint8 public constant SG_TYPE_SWAP_REMOTE = 1;

    /**
     * @dev OFT packet type
     */
    uint16 public constant PT_SEND_AND_CALL = 1;

    constructor() {
        _disableInitializers();
    }

    function initialize(IPoolRegistry poolRegistry_) external initializer {
        if (address(poolRegistry_) == address(0)) revert AddressIsNull();
        poolRegistry = poolRegistry_;
    }

    /**
     * @notice Get LZ args for the swap and callback's trigger execution
     * @dev Must be called on the chain where the swap will be executed (a.k.a. destination chain)
     * @param srcChainId_ Source chain's LZ id (i.e. user-facing chain)
     * @param dstChainId_ Destination chain's LZ id (i.e. chain used for swap)
     */
    function getFlashRepaySwapAndCallbackLzArgs(
        uint16 srcChainId_,
        uint16 dstChainId_
    ) external view returns (bytes memory _lzArgs) {
        return
            CrossChainLib.encodeLzArgs({
                dstChainId_: dstChainId_,
                callbackNativeFee_: quoteFlashRepayCallbackNativeFee(srcChainId_),
                swapTxGasLimit_: _getCrossChainDispatcher().flashRepaySwapTxGasLimit()
            });
    }

    /**
     * @notice Get LZ args for the swap and callback's trigger execution
     * @dev Must be called on the chain where the swap will be executed (a.k.a. destination chain)
     * @param srcChainId_ Source chain's LZ id (i.e. user-facing chain)
     * @param dstChainId_ Destination chain's LZ id (i.e. chain used for swap)
     */
    function getLeverageSwapAndCallbackLzArgs(
        uint16 srcChainId_,
        uint16 dstChainId_
    ) external view returns (bytes memory _lzArgs) {
        return
            CrossChainLib.encodeLzArgs({
                dstChainId_: dstChainId_,
                callbackNativeFee_: quoteLeverageCallbackNativeFee(srcChainId_),
                swapTxGasLimit_: _getCrossChainDispatcher().leverageSwapTxGasLimit()
            });
    }

    /**
     * @notice Get the LZ (native) fee for the `crossChainLeverageCallback()` call
     * @param srcChainId_ Source chain's LZ id (i.e. user-facing chain)
     * @return _callbackTxNativeFee The fee in native coin
     */
    function quoteLeverageCallbackNativeFee(uint16 srcChainId_) public view returns (uint256 _callbackTxNativeFee) {
        ICrossChainDispatcher _crossChainDispatcher = _getCrossChainDispatcher();
        (_callbackTxNativeFee, ) = _crossChainDispatcher.stargateComposer().quoteLayerZeroFee({
            _dstChainId: srcChainId_,
            _functionType: SG_TYPE_SWAP_REMOTE,
            _toAddress: abi.encodePacked(address(type(uint160).max)),
            _transferAndCallPayload: CrossChainLib.encodeLeverageCallbackPayload(
                address(type(uint160).max),
                type(uint256).max
            ),
            _lzTxParams: IStargateRouter.lzTxObj({
                dstGasForCall: _crossChainDispatcher.leverageCallbackTxGasLimit(),
                dstNativeAmount: 0,
                dstNativeAddr: ""
            })
        });
    }

    /**
     * @notice Get the LZ (native) fee for the `crossChainFlashRepayCallback()` call
     * @param srcChainId_ Source chain's LZ id (i.e. user-facing chain)
     * @return _callbackTxNativeFee The fee in native coin
     */
    function quoteFlashRepayCallbackNativeFee(uint16 srcChainId_) public view returns (uint256 _callbackTxNativeFee) {
        ICrossChainDispatcher _crossChainDispatcher = _getCrossChainDispatcher();
        uint64 _callbackTxGasLimit = _crossChainDispatcher.flashRepayCallbackTxGasLimit();

        bytes memory _lzPayload = abi.encode(
            PT_SEND_AND_CALL,
            abi.encodePacked(msg.sender),
            abi.encodePacked(address(type(uint160).max)),
            type(uint256).max,
            CrossChainLib.encodeFlashRepayCallbackPayload(
                address(type(uint160).max),
                address(type(uint160).max),
                type(uint256).max
            ),
            _callbackTxGasLimit
        );

        (_callbackTxNativeFee, ) = IStargateBridge(_crossChainDispatcher.stargateComposer().stargateBridge())
            .layerZeroEndpoint()
            .estimateFees(
                srcChainId_,
                address(this),
                _lzPayload,
                false,
                abi.encodePacked(
                    LZ_ADAPTER_PARAMS_VERSION,
                    uint256(_crossChainDispatcher.lzBaseGasLimit() + _callbackTxGasLimit),
                    uint256(0),
                    address(0)
                )
            );
    }

    /**
     * @notice Get the LZ (native) fee for the `triggerFlashRepay()` call
     * @param proxyOFT_ The synthetic token's Proxy OFT contract
     * @param lzArgs_ The LZ args for swap transaction (See: `getFlashRepaySwapAndCallbackLzArgs()`)
     * @return _nativeFee The fee in native coin
     */
    function quoteCrossChainFlashRepayNativeFee(
        IProxyOFT proxyOFT_,
        bytes calldata lzArgs_
    ) external view returns (uint256 _nativeFee) {
        (uint16 _dstChainId, uint256 _callbackTxNativeFee, uint64 _swapTxGasLimit_) = CrossChainLib.decodeLzArgs(
            lzArgs_
        );

        bytes memory _dstProxyOFT = abi.encodePacked(proxyOFT_.getProxyOFTOf(_dstChainId));

        (_nativeFee, ) = _getCrossChainDispatcher().stargateComposer().quoteLayerZeroFee({
            _dstChainId: _dstChainId,
            _functionType: SG_TYPE_SWAP_REMOTE,
            _toAddress: _dstProxyOFT,
            _transferAndCallPayload: CrossChainLib.encodeFlashRepaySwapPayload(
                address(type(uint160).max),
                address(type(uint160).max),
                type(uint256).max,
                address(type(uint160).max),
                type(uint256).max
            ),
            _lzTxParams: IStargateRouter.lzTxObj({
                dstGasForCall: _swapTxGasLimit_,
                dstNativeAmount: _callbackTxNativeFee,
                dstNativeAddr: _dstProxyOFT
            })
        });
    }

    /**
     * @notice Get the LZ (native) fee for the `triggerLeverageSwap()` call
     * @param proxyOFT_ The synthetic token's Proxy OFT contract
     * @param lzArgs_ The LZ args for swap transaction (See: `getLeverageSwapAndCallbackLzArgs()`)
     * @return _nativeFee The fee in native coin
     */
    function quoteCrossChainLeverageNativeFee(
        IProxyOFT proxyOFT_,
        bytes calldata lzArgs_
    ) public view returns (uint256 _nativeFee) {
        uint16 _dstChainId;
        address _dstProxyOFT;
        bytes memory _payload;
        bytes memory _adapterParams;
        uint64 _swapTxGasLimit;
        {
            _payload = CrossChainLib.encodeLeverageSwapPayload(
                address(type(uint160).max),
                address(type(uint160).max),
                type(uint256).max,
                type(uint256).max,
                address(type(uint160).max),
                type(uint256).max
            );

            uint256 _callbackTxNativeFee;
            (_dstChainId, _callbackTxNativeFee, _swapTxGasLimit) = CrossChainLib.decodeLzArgs(lzArgs_);

            _dstProxyOFT = proxyOFT_.getProxyOFTOf(_dstChainId);

            _adapterParams = abi.encodePacked(
                LZ_ADAPTER_PARAMS_VERSION,
                uint256(_getCrossChainDispatcher().lzBaseGasLimit() + _swapTxGasLimit),
                _callbackTxNativeFee,
                _dstProxyOFT
            );
        }

        (_nativeFee, ) = proxyOFT_.estimateSendAndCallFee({
            _dstChainId: _dstChainId,
            _toAddress: abi.encodePacked(_dstProxyOFT),
            _amount: type(uint256).max,
            _payload: _payload,
            _dstGasForCall: _swapTxGasLimit,
            _useZro: false,
            _adapterParams: _adapterParams
        });
    }

    function _getCrossChainDispatcher() private view returns (ICrossChainDispatcher) {
        return poolRegistry.crossChainDispatcher();
    }
}

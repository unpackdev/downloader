// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ReentrancyGuard.sol";
import "./BytesLib.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IStargatePool.sol";
import "./IStargateFactory.sol";
import "./CrossChainDispatcherStorage.sol";
import "./IProxyOFT.sol";
import "./ISmartFarmingManager.sol";
import "./ISyntheticToken.sol";
import "./ISwapper.sol";
import "./CrossChainLib.sol";

error AddressIsNull();
error InvalidMsgSender();
error BridgingIsPaused();
error InvalidFromAddress();
error InvalidToAddress();
error NewValueIsSameAsCurrent();
error SenderIsNotGovernor();
error DestinationChainNotAllowed();
error InvalidOperationType();
error InvalidETHSender();
error InvalidPayload();

/**
 * @title Cross-chain dispatcher
 */
contract CrossChainDispatcher is ReentrancyGuard, CrossChainDispatcherStorageV1 {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    string public constant VERSION = "1.3.0";

    /**
     * @dev LayerZero adapter param version
     * See more: https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters
     */
    uint16 private constant LZ_ADAPTER_PARAMS_VERSION = 2;

    uint256 private constant MAX_BPS = 100_00;

    struct LayerZeroParams {
        address tokenIn;
        uint16 dstChainId;
        uint256 amountIn;
        uint256 nativeFee;
        bytes payload;
        address refundAddress;
        uint64 dstGasForCall;
        uint256 dstNativeAmount;
    }

    /// @notice Emitted when Lz base gas limit updated
    event LzBaseGasLimitUpdated(uint256 oldLzBaseGasLimit, uint256 newLzBaseGasLimit);

    /// @notice Emitted when Stargate composer is updated
    event StargateComposerUpdated(IStargateComposer oldStargateComposer, IStargateComposer newStargateComposer);

    /// @notice Emitted when Stargate pool id is updated
    event StargatePoolIdUpdated(address indexed token, uint256 oldPoolId, uint256 newPoolId);

    /// @notice Emitted when Stargate slippage is updated
    event StargateSlippageUpdated(uint256 oldStargateSlippage, uint256 newStargateSlippage);

    /// @notice Emitted when synth->underlying L1 swap gas limit is updated
    event LeverageSwapTxGasLimitUpdated(uint64 oldSwapTxGasLimit, uint64 newSwapTxGasLimit);

    /// @notice Emitted when leverage callback gas limit is updated
    event LeverageCallbackTxGasLimitUpdated(uint64 oldCallbackTxGasLimit, uint64 newCallbackTxGasLimit);

    /// @notice Emitted when underlying->synth L1 swap gas limit is updated
    event FlashRepaySwapTxGasLimitUpdated(uint64 oldSwapTxGasLimit, uint64 newSwapTxGasLimit);

    /// @notice Emitted when flash repay callback gas limit is updated
    event FlashRepayCallbackTxGasLimitUpdated(uint64 oldCallbackTxGasLimit, uint64 newCallbackTxGasLimit);

    /// @notice Emitted when flag for pause bridge transfer is toggled
    event BridgingIsActiveUpdated(bool newIsActive);

    /// @notice Emitted when a Cross-chain dispatcher mapping is updated
    event CrossChainDispatcherUpdated(uint16 chainId, address oldCrossChainDispatcher, address newCrossChainDispatcher);

    /// @notice Emitted when flag for support chain is toggled
    event DestinationChainIsSupportedUpdated(uint16 chainId, bool newIsSupported);

    modifier onlyGovernor() {
        if (msg.sender != poolRegistry.governor()) revert SenderIsNotGovernor();
        _;
    }

    modifier onlyIfBridgingIsNotPaused() {
        if (!isBridgingActive) revert BridgingIsPaused();
        _;
    }

    modifier onlyIfSmartFarmingManager() {
        IPool _pool = IManageable(msg.sender).pool();
        if (!poolRegistry.isPoolRegistered(address(_pool))) revert InvalidMsgSender();
        if (msg.sender != address(_pool.smartFarmingManager())) revert InvalidMsgSender();
        _;
    }

    modifier onlyIfStargateRouter() {
        if (msg.sender != address(stargateComposer.stargateRouter())) revert InvalidMsgSender();
        _;
    }

    modifier onlyIfProxyOFT() {
        if (!_isValidProxyOFT(msg.sender)) revert InvalidMsgSender();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(IPoolRegistry poolRegistry_, address weth_, address sgeth_) external initializer {
        if (address(poolRegistry_) == address(0)) revert AddressIsNull();

        __ReentrancyGuard_init();

        poolRegistry = poolRegistry_;
        stargateSlippage = 50; // 0.5%
        lzBaseGasLimit = 200_000;
        flashRepayCallbackTxGasLimit = 750_000;
        flashRepaySwapTxGasLimit = 500_000;
        leverageCallbackTxGasLimit = 750_000;
        leverageSwapTxGasLimit = 750_000;
        weth = weth_;
        sgeth = sgeth_;
    }

    /**
     * @notice Called by the OFT contract when tokens are received from source chain.
     * @dev Token received are swapped to another token
     * @param srcChainId_ The chain id of the source chain.
     * @param from_ The address of the account who calls the sendAndCall() on the source chain.
     * @param amount_ The amount of tokens to transfer.
     * @param payload_ Additional data with no specified format.
     */
    function onOFTReceived(
        uint16 srcChainId_,
        bytes calldata /*srcAddress_*/,
        uint64 /*nonce_*/,
        bytes calldata from_,
        uint amount_,
        bytes calldata payload_
    ) external override onlyIfProxyOFT {
        address _from = from_.toAddress(0);
        if (_from == address(0) || _from != crossChainDispatcherOf[srcChainId_]) revert InvalidFromAddress();

        uint8 _op = CrossChainLib.getOperationType(payload_);

        if (_op == CrossChainLib.FLASH_REPAY) {
            _crossChainFlashRepayCallback(amount_, payload_);
        } else if (_op == CrossChainLib.LEVERAGE) {
            _swapAndTriggerLeverageCallback(srcChainId_, amount_, payload_);
        } else {
            revert InvalidOperationType();
        }
    }

    /**
     * @dev Finalize cross-chain flash repay process. The callback may fail due to slippage.
     */
    function _crossChainFlashRepayCallback(uint amount_, bytes calldata payload_) private {
        (address proxyOFT_, address _smartFarmingManager, uint256 _requestId) = CrossChainLib
            .decodeFlashRepayCallbackPayload(payload_);

        IERC20 _syntheticToken = IERC20(IProxyOFT(proxyOFT_).token());
        _syntheticToken.safeApprove(_smartFarmingManager, 0);
        _syntheticToken.safeApprove(_smartFarmingManager, amount_);
        ISmartFarmingManager(_smartFarmingManager).crossChainFlashRepayCallback(_requestId, amount_);
    }

    /**
     * @dev Swap synthetic token for underlying and trigger callback call
     */
    function _swapAndTriggerLeverageCallback(uint16 srcChainId_, uint amountIn_, bytes calldata payload_) private {
        // 1. Swap
        (
            address _srcSmartFarmingManager,
            address _dstProxyOFT,
            uint256 _requestId,
            uint256 _underlyingPoolId,
            address _account,
            uint256 _amountOutMin
        ) = CrossChainLib.decodeLeverageSwapPayload(payload_);

        address _underlying = IStargatePool(IStargateFactory(stargateComposer.factory()).getPool(_underlyingPoolId))
            .token();

        if (_underlying == sgeth) _underlying = weth;

        amountIn_ = _swap({
            requestId_: _requestId,
            tokenIn_: IProxyOFT(_dstProxyOFT).token(),
            tokenOut_: _underlying,
            amountIn_: amountIn_,
            amountOutMin_: _amountOutMin
        });

        // 2. Transfer underlying to source chain
        uint16 _srcChainId = srcChainId_;

        _sendUsingStargate(
            LayerZeroParams({
                tokenIn: _underlying,
                dstChainId: _srcChainId,
                amountIn: amountIn_,
                nativeFee: poolRegistry.quoter().quoteLeverageCallbackNativeFee(_srcChainId),
                payload: CrossChainLib.encodeLeverageCallbackPayload(_srcSmartFarmingManager, _requestId),
                refundAddress: _account,
                dstGasForCall: leverageCallbackTxGasLimit,
                dstNativeAmount: 0
            })
        );
    }

    /**
     * @notice Receive token and payload from Stargate
     * @param srcChainId_ The chain id of the source chain.
     * @param srcAddress_ The remote Bridge address
     * @param token_ The token contract on the local chain
     * @param amountLD_ The qty of local _token contract tokens
     * @param sgPayload_ The original payload encoded with further data added by StargateComposer
     */
    function sgReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint256 /*nonce_*/,
        address token_,
        uint256 amountLD_,
        bytes memory sgPayload_
    ) external override onlyIfStargateRouter {
        // Note: Stargate uses SGETH as `token_` when receiving native ETH
        if (token_ == sgeth) {
            IWETH(weth).deposit{value: amountLD_}();
            token_ = weth;
        }

        address _srcAddress = abi.decode(srcAddress_, (address));
        (address _to, address _sender, bytes memory _payload) = _decodePayloadFromSgComposer(sgPayload_);

        if (
            _srcAddress == address(0) ||
            _srcAddress != stargateComposer.peers(srcChainId_) ||
            _sender != crossChainDispatcherOf[srcChainId_]
        ) revert InvalidFromAddress();

        if (_to == address(0) || _to != address(this)) revert InvalidToAddress();

        uint8 _op = CrossChainLib.getOperationType(_payload);

        if (_op == CrossChainLib.LEVERAGE) {
            _crossChainLeverageCallback(token_, amountLD_, _payload);
        } else if (_op == CrossChainLib.FLASH_REPAY) {
            _swapAndTriggerFlashRepayCallback(srcChainId_, token_, amountLD_, _payload);
        } else {
            revert InvalidOperationType();
        }
    }

    /**
     * @dev Finalize cross-chain leverage process. The callback may fail due to slippage.
     */
    function _crossChainLeverageCallback(address token_, uint256 amount_, bytes memory payload_) private {
        (address _smartFarmingManager, uint256 _requestId) = CrossChainLib.decodeLeverageCallbackPayload(payload_);
        IERC20(token_).safeApprove(_smartFarmingManager, 0);
        IERC20(token_).safeApprove(_smartFarmingManager, amount_);
        ISmartFarmingManager(_smartFarmingManager).crossChainLeverageCallback(_requestId, amount_);
    }

    /**
     * @dev Send synthetic token cross-chain
     */
    function _sendUsingLayerZero(LayerZeroParams memory params_) private {
        address _to = crossChainDispatcherOf[params_.dstChainId];
        if (_to == address(0)) revert AddressIsNull();

        bytes memory _adapterParams = abi.encodePacked(
            LZ_ADAPTER_PARAMS_VERSION,
            uint256(lzBaseGasLimit + params_.dstGasForCall),
            params_.dstNativeAmount,
            (params_.dstNativeAmount > 0) ? _to : address(0)
        );

        ISyntheticToken(params_.tokenIn).proxyOFT().sendAndCall{value: params_.nativeFee}({
            _from: address(this),
            _dstChainId: params_.dstChainId,
            _toAddress: abi.encodePacked(_to),
            _amount: params_.amountIn,
            _payload: params_.payload,
            _dstGasForCall: params_.dstGasForCall,
            _refundAddress: payable(params_.refundAddress),
            _zroPaymentAddress: address(0),
            _adapterParams: _adapterParams
        });
    }

    /**
     * @dev Swap underlying for synthetic token and trigger callback call
     */
    function _swapAndTriggerFlashRepayCallback(
        uint16 srcChainId_,
        address token_,
        uint256 amount_,
        bytes memory payload_
    ) private {
        // 1. Swap
        (
            address _srcSmartFarmingManager,
            address _dstProxyOFT,
            uint256 _requestId,
            address _account,
            uint256 _amountOutMin
        ) = CrossChainLib.decodeFlashRepaySwapPayload(payload_);

        address _syntheticToken = IProxyOFT(_dstProxyOFT).token();
        amount_ = _swap({
            requestId_: _requestId,
            tokenIn_: token_,
            tokenOut_: _syntheticToken,
            amountIn_: amount_,
            amountOutMin_: _amountOutMin
        });

        // 2. Transfer synthetic token to source chain
        uint16 _srcChainId = srcChainId_;
        address _srcProxyOFT = IProxyOFT(_dstProxyOFT).getProxyOFTOf(_srcChainId);

        _sendUsingLayerZero(
            LayerZeroParams({
                tokenIn: _syntheticToken,
                dstChainId: _srcChainId,
                amountIn: amount_,
                payload: CrossChainLib.encodeFlashRepayCallbackPayload(
                    _srcProxyOFT,
                    _srcSmartFarmingManager,
                    _requestId
                ),
                refundAddress: _account,
                dstGasForCall: flashRepayCallbackTxGasLimit,
                dstNativeAmount: 0,
                nativeFee: poolRegistry.quoter().quoteFlashRepayCallbackNativeFee(_srcChainId)
            })
        );
    }

    /**
     * @notice Retry swap underlying and trigger callback.
     * @param srcChainId_ srcChainId
     * @param srcAddress_ srcAddress
     * @param nonce_ nonce
     * @param newAmountOutMin_ If swap failed due to slippage, caller may send lower newAmountOutMin_
     */
    function retrySwapAndTriggerFlashRepayCallback(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint256 nonce_,
        uint256 newAmountOutMin_
    ) external nonReentrant {
        IStargateRouter _stargateRouter = stargateComposer.stargateRouter();

        (, , , bytes memory _sgPayload) = _stargateRouter.cachedSwapLookup(srcChainId_, srcAddress_, nonce_);

        (, , bytes memory _payload) = _decodePayloadFromSgComposer(_sgPayload);

        (, , uint256 _requestId, address _account, ) = CrossChainLib.decodeFlashRepaySwapPayload(_payload);

        if (msg.sender != _account) revert InvalidMsgSender();

        swapAmountOutMin[_requestId] = newAmountOutMin_;

        _stargateRouter.clearCachedSwap(srcChainId_, srcAddress_, nonce_);
    }

    /**
     * @notice Retry swap and trigger callback.
     * @param srcChainId_ srcChainId
     * @param srcAddress_ srcAddress
     * @param nonce_ nonce
     * @param amount_ amount
     * @param payload_ payload
     * @param newAmountOutMin_ If swap failed due to slippage, caller may send lower newAmountOutMin_
     */
    function retrySwapAndTriggerLeverageCallback(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        uint amount_,
        bytes calldata payload_,
        uint256 newAmountOutMin_
    ) external nonReentrant {
        (, address _dstProxyOFT, uint256 _requestId, , address _account, ) = CrossChainLib.decodeLeverageSwapPayload(
            payload_
        );

        if (!_isValidProxyOFT(_dstProxyOFT)) revert InvalidPayload();
        if (msg.sender != _account) revert InvalidMsgSender();

        swapAmountOutMin[_requestId] = newAmountOutMin_;

        // Note: `retryOFTReceived()` has checks to ensure that the args are consistent
        bytes memory _from = abi.encodePacked(crossChainDispatcherOf[srcChainId_]);
        IProxyOFT(_dstProxyOFT).retryOFTReceived(
            srcChainId_,
            srcAddress_,
            nonce_,
            _from,
            address(this),
            amount_,
            payload_
        );
    }

    /***
     * @notice Trigger swap using Stargate for flashRepay.
     * @param requestId_ Request id.
     * @param account_ User address and also refund address
     * @param tokenIn_ tokenIn
     * @param tokenOut_ tokenOut
     * @param amountIn_ amountIn_
     * @param amountOutMin_ amountOutMin_
     * @param lzArgs_ LayerZero method argument
     */
    function triggerFlashRepaySwap(
        uint256 requestId_,
        address payable account_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        bytes calldata lzArgs_
    ) external payable override nonReentrant onlyIfSmartFarmingManager onlyIfBridgingIsNotPaused {
        address _account = account_; // stack too deep

        (uint16 _dstChainId, uint256 callbackTxNativeFee_, uint64 flashRepaySwapTxGasLimit_) = CrossChainLib
            .decodeLzArgs(lzArgs_);

        bytes memory _payload;
        {
            address _dstProxyOFT = ISyntheticToken(tokenOut_).proxyOFT().getProxyOFTOf(_dstChainId);

            if (_dstProxyOFT == address(0)) revert AddressIsNull();
            if (!isDestinationChainSupported[_dstChainId]) revert DestinationChainNotAllowed();

            uint256 _requestId = requestId_; // stack too deep

            _payload = CrossChainLib.encodeFlashRepaySwapPayload({
                srcSmartFarmingManager_: msg.sender,
                dstProxyOFT_: _dstProxyOFT,
                requestId_: _requestId,
                account_: _account,
                amountOutMin_: amountOutMin_
            });
        }

        _sendUsingStargate(
            LayerZeroParams({
                tokenIn: tokenIn_,
                dstChainId: _dstChainId,
                amountIn: amountIn_,
                nativeFee: msg.value,
                payload: _payload,
                refundAddress: _account,
                dstGasForCall: flashRepaySwapTxGasLimit_,
                dstNativeAmount: callbackTxNativeFee_
            })
        );
    }

    /***
     * @notice Send synthetic token and trigger swap at destination chain
     * @dev Not checking if bridging is pause because `ProxyOFT._debitFrom()` does it
     * @param requestId_ Request id.
     * @param account_ User address and also refund address
     * @param tokenOut_ tokenOut
     * @param amountIn_ amountIn
     * @param amountOutMin_ amountOutMin
     * @param lzArgs_ LayerZero method argument
     */
    function triggerLeverageSwap(
        uint256 requestId_,
        address payable account_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        bytes calldata lzArgs_
    ) external payable override nonReentrant onlyIfSmartFarmingManager {
        address _account = account_; // stack too deep

        (uint16 _dstChainId, uint256 _callbackTxNativeFee, uint64 _leverageSwapTxGasLimit) = CrossChainLib.decodeLzArgs(
            lzArgs_
        );

        bytes memory _payload;
        {
            address _dstProxyOFT = ISyntheticToken(tokenIn_).proxyOFT().getProxyOFTOf(_dstChainId);

            if (_dstProxyOFT == address(0)) revert AddressIsNull();
            if (!isDestinationChainSupported[_dstChainId]) revert DestinationChainNotAllowed();

            uint256 _requestId = requestId_; // stack too deep
            address _tokenOut = tokenOut_; // stack too deep
            uint256 _amountOutMin = amountOutMin_; // stack too deep

            _payload = CrossChainLib.encodeLeverageSwapPayload({
                srcSmartFarmingManager_: msg.sender,
                dstProxyOFT_: _dstProxyOFT,
                requestId_: _requestId,
                sgPoolId_: stargatePoolIdOf[_tokenOut],
                account_: _account,
                amountOutMin_: _amountOutMin
            });
        }

        _sendUsingLayerZero(
            LayerZeroParams({
                tokenIn: tokenIn_,
                dstChainId: _dstChainId,
                amountIn: amountIn_,
                payload: _payload,
                refundAddress: _account,
                dstGasForCall: _leverageSwapTxGasLimit,
                dstNativeAmount: _callbackTxNativeFee,
                nativeFee: msg.value
            })
        );
    }

    /**
     * @dev The `StargateComposer` contract adds further addresses to the original payload
     */
    function _decodePayloadFromSgComposer(
        bytes memory payload_
    ) private pure returns (address _to, address _sender, bytes memory _payload) {
        _to = payload_.toAddress(0); // The original `swap()` `_to` arg
        _sender = payload_.toAddress(20); // The address who called the `StargateComposer`
        _payload = payload_.slice(40, payload_.length - 40);
    }

    /**
     * @dev Check wether an address is a proxyOFT or not
     */
    function _isValidProxyOFT(address proxyOFT_) private view returns (bool) {
        ISyntheticToken _syntheticToken = ISyntheticToken(IProxyOFT(proxyOFT_).token());
        if (!poolRegistry.doesSyntheticTokenExist(_syntheticToken)) return false;
        if (proxyOFT_ != address(_syntheticToken.proxyOFT())) return false;

        return true;
    }

    /**
     * @dev Send underlying token cross-chain
     */
    function _sendUsingStargate(LayerZeroParams memory params_) private {
        IStargateRouter.lzTxObj memory _lzTxParams;
        bytes memory _to = abi.encodePacked(crossChainDispatcherOf[params_.dstChainId]);
        {
            if (_to.toAddress(0) == address(0)) revert AddressIsNull();

            _lzTxParams = IStargateRouter.lzTxObj({
                dstGasForCall: params_.dstGasForCall,
                dstNativeAmount: params_.dstNativeAmount,
                dstNativeAddr: (params_.dstNativeAmount > 0) ? _to : abi.encode(0)
            });
        }

        uint256 _poolId = stargatePoolIdOf[params_.tokenIn];
        uint256 _amountOutMin = (params_.amountIn * (MAX_BPS - stargateSlippage)) / MAX_BPS;
        bytes memory _payload = params_.payload;

        IStargateComposer _stargateComposer = stargateComposer;

        // Note: StargateComposer only accepts native for ETH pool
        if (params_.tokenIn == weth) {
            IWETH(weth).withdraw(params_.amountIn);
            params_.nativeFee += params_.amountIn;
        } else {
            IERC20(params_.tokenIn).safeApprove(address(_stargateComposer), 0);
            IERC20(params_.tokenIn).safeApprove(address(_stargateComposer), params_.amountIn);
        }

        _stargateComposer.swap{value: params_.nativeFee}({
            _dstChainId: params_.dstChainId,
            _srcPoolId: _poolId,
            _dstPoolId: _poolId,
            _refundAddress: payable(params_.refundAddress),
            _amountLD: params_.amountIn,
            _minAmountLD: _amountOutMin,
            _lzTxParams: _lzTxParams,
            _to: _to,
            _payload: _payload
        });
    }

    /**
     * @dev Perform a swap considering slippage param from user
     */
    function _swap(
        uint256 requestId_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_
    ) private returns (uint256 _amountOut) {
        // 1. Use updated slippage if exist
        uint256 _storedAmountOutMin = swapAmountOutMin[requestId_];
        if (_storedAmountOutMin > 0) {
            // Use stored slippage and clear it
            amountOutMin_ = _storedAmountOutMin;
            delete swapAmountOutMin[requestId_];
        }

        // 2. Perform swap
        ISwapper _swapper = poolRegistry.swapper();
        IERC20(tokenIn_).safeApprove(address(_swapper), 0);
        IERC20(tokenIn_).safeApprove(address(_swapper), amountIn_);
        _amountOut = _swapper.swapExactInput({
            tokenIn_: tokenIn_,
            tokenOut_: tokenOut_,
            amountIn_: amountIn_,
            amountOutMin_: amountOutMin_,
            receiver_: address(this)
        });
    }

    /**
     * @notice Update flash repay callback tx gas limit
     */
    function updateFlashRepayCallbackTxGasLimit(uint64 newFlashRepayCallbackTxGasLimit_) external onlyGovernor {
        uint64 _currentFlashRepayCallbackTxGasLimit = flashRepayCallbackTxGasLimit;
        if (newFlashRepayCallbackTxGasLimit_ == _currentFlashRepayCallbackTxGasLimit) revert NewValueIsSameAsCurrent();
        emit FlashRepayCallbackTxGasLimitUpdated(
            _currentFlashRepayCallbackTxGasLimit,
            newFlashRepayCallbackTxGasLimit_
        );
        flashRepayCallbackTxGasLimit = newFlashRepayCallbackTxGasLimit_;
    }

    /**
     * @notice Update flash repay swap tx gas limit
     */
    function updateFlashRepaySwapTxGasLimit(uint64 newFlashRepaySwapTxGasLimit_) external onlyGovernor {
        uint64 _currentFlashRepaySwapTxGasLimit = flashRepaySwapTxGasLimit;
        if (newFlashRepaySwapTxGasLimit_ == _currentFlashRepaySwapTxGasLimit) revert NewValueIsSameAsCurrent();
        emit FlashRepaySwapTxGasLimitUpdated(_currentFlashRepaySwapTxGasLimit, newFlashRepaySwapTxGasLimit_);
        flashRepaySwapTxGasLimit = newFlashRepaySwapTxGasLimit_;
    }

    /**
     * @notice Update leverage callback tx gas limit
     */
    function updateLeverageCallbackTxGasLimit(uint64 newLeverageCallbackTxGasLimit_) external onlyGovernor {
        uint64 _currentLeverageCallbackTxGasLimit = leverageCallbackTxGasLimit;
        if (newLeverageCallbackTxGasLimit_ == _currentLeverageCallbackTxGasLimit) revert NewValueIsSameAsCurrent();
        emit LeverageCallbackTxGasLimitUpdated(_currentLeverageCallbackTxGasLimit, newLeverageCallbackTxGasLimit_);
        leverageCallbackTxGasLimit = newLeverageCallbackTxGasLimit_;
    }

    /**
     * @notice Update leverage swap tx gas limit
     */
    function updateLeverageSwapTxGasLimit(uint64 newLeverageSwapTxGasLimit_) external onlyGovernor {
        uint64 _currentSwapTxGasLimit = leverageSwapTxGasLimit;
        if (newLeverageSwapTxGasLimit_ == _currentSwapTxGasLimit) revert NewValueIsSameAsCurrent();
        emit LeverageSwapTxGasLimitUpdated(_currentSwapTxGasLimit, newLeverageSwapTxGasLimit_);
        leverageSwapTxGasLimit = newLeverageSwapTxGasLimit_;
    }

    /**
     * @notice Update Lz base gas limit
     */
    function updateLzBaseGasLimit(uint256 newLzBaseGasLimit_) external onlyGovernor {
        uint256 _currentBaseGasLimit = lzBaseGasLimit;
        if (newLzBaseGasLimit_ == _currentBaseGasLimit) revert NewValueIsSameAsCurrent();
        emit LzBaseGasLimitUpdated(_currentBaseGasLimit, newLzBaseGasLimit_);
        lzBaseGasLimit = newLzBaseGasLimit_;
    }

    /**
     * @notice Update Stargate pool id of token.
     * @dev Use LZ ids (https://stargateprotocol.gitbook.io/stargate/developers/pool-ids)
     */
    function updateStargatePoolIdOf(address token_, uint256 newPoolId_) external onlyGovernor {
        uint256 _currentPoolId = stargatePoolIdOf[token_];
        if (newPoolId_ == _currentPoolId) revert NewValueIsSameAsCurrent();
        emit StargatePoolIdUpdated(token_, _currentPoolId, newPoolId_);
        stargatePoolIdOf[token_] = newPoolId_;
    }

    /**
     * @notice Update Stargate slippage
     */
    function updateStargateSlippage(uint256 newStargateSlippage_) external onlyGovernor {
        uint256 _currentStargateSlippage = stargateSlippage;
        if (newStargateSlippage_ == _currentStargateSlippage) revert NewValueIsSameAsCurrent();
        emit StargateSlippageUpdated(_currentStargateSlippage, newStargateSlippage_);
        stargateSlippage = newStargateSlippage_;
    }

    /**
     * @notice Update StargateComposer
     */
    function updateStargateComposer(IStargateComposer newStargateComposer_) external onlyGovernor {
        IStargateComposer _currentStargateComposer = stargateComposer;
        if (newStargateComposer_ == _currentStargateComposer) revert NewValueIsSameAsCurrent();
        emit StargateComposerUpdated(_currentStargateComposer, newStargateComposer_);
        stargateComposer = newStargateComposer_;
    }

    /**
     * @notice Pause/Unpause bridge transfers
     */
    function toggleBridgingIsActive() external onlyGovernor {
        bool _newIsBridgingActive = !isBridgingActive;
        emit BridgingIsActiveUpdated(_newIsBridgingActive);
        isBridgingActive = _newIsBridgingActive;
    }

    /**
     * @notice Update Cross-chain dispatcher mapping
     */
    function updateCrossChainDispatcherOf(uint16 chainId_, address crossChainDispatcher_) external onlyGovernor {
        address _current = crossChainDispatcherOf[chainId_];
        if (crossChainDispatcher_ == _current) revert NewValueIsSameAsCurrent();
        emit CrossChainDispatcherUpdated(chainId_, _current, crossChainDispatcher_);
        crossChainDispatcherOf[chainId_] = crossChainDispatcher_;
    }

    /**
     * @notice Allow/Disallow destination chain
     * @dev Use LZ chain id
     */
    function toggleDestinationChainIsActive(uint16 chainId_) external onlyGovernor {
        bool _isDestinationChainSupported = !isDestinationChainSupported[chainId_];
        emit BridgingIsActiveUpdated(_isDestinationChainSupported);
        isDestinationChainSupported[chainId_] = _isDestinationChainSupported;
    }
}

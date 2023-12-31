// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Manageable.sol";
import "./SmartFarmingManagerStorage.sol";
import "./WadRayMath.sol";
import "./CrossChainLib.sol";

error SyntheticDoesNotExist();
error PoolIsNull();
error FlashRepaySlippageTooHigh();
error LeverageTooLow();
error LeverageTooHigh();
error LeverageSlippageTooHigh();
error PositionIsNotHealthy();
error AmountIsZero();
error AmountIsTooHigh();
error DepositTokenDoesNotExist();
error AddressIsNull();
error NewValueIsSameAsCurrent();
error CrossChainRequestInvalidKey();
error SenderIsNotCrossChainDispatcher();
error CrossChainRequestCompletedAlready();
error TokenInIsNull();
error SenderIsNotAccount();

/**
 * @title SmartFarmingManager contract
 */
contract SmartFarmingManager is ReentrancyGuard, Manageable, SmartFarmingManagerStorageV1 {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISyntheticToken;
    using WadRayMath for uint256;

    string public constant VERSION = "1.3.0";

    /// @notice Emitted when a cross-chain leverage request is finalized
    event CrossChainLeverageFinished(uint256 indexed id);

    /// @notice Emitted when a cross-chain leverage request is created
    event CrossChainLeverageStarted(uint256 indexed id);

    /// @notice Emitted when a cross-chain flash repay request is finalized
    event CrossChainFlashRepayFinished(uint256 indexed id);

    /// @notice Emitted when a cross-chain flash repay request is created
    event CrossChainFlashRepayStarted(uint256 indexed id);

    /// @notice Emitted when debt is flash repaid
    event FlashRepaid(
        ISyntheticToken indexed syntheticToken,
        IDepositToken indexed depositToken,
        uint256 withdrawn,
        uint256 repaid
    );

    /// @notice Emitted when deposit is leveraged
    event Leveraged(
        IERC20 indexed tokenIn,
        IDepositToken indexed depositToken,
        ISyntheticToken indexed syntheticToken,
        uint256 leverage,
        uint256 amountIn,
        uint256 issued,
        uint256 deposited
    );

    /**
     * @dev Throws if sender isn't a valid ProxyOFT contract
     */
    modifier onlyIfCrossChainDispatcher() {
        if (msg.sender != address(crossChainDispatcher())) revert SenderIsNotCrossChainDispatcher();
        _;
    }

    /**
     * @dev Throws if deposit token doesn't exist
     */
    modifier onlyIfDepositTokenExists(IDepositToken depositToken_) {
        if (!pool.doesDepositTokenExist(depositToken_)) revert DepositTokenDoesNotExist();
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists(ISyntheticToken syntheticToken_) {
        if (!pool.doesSyntheticTokenExist(syntheticToken_)) revert SyntheticDoesNotExist();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IPool pool_) public initializer {
        if (address(pool_) == address(0)) revert PoolIsNull();
        __ReentrancyGuard_init();
        __Manageable_init(pool_);
    }

    /**
     * @notice Get the Cross-chain dispatcher contract
     */
    function crossChainDispatcher() public view returns (ICrossChainDispatcher _crossChainDispatcher) {
        return pool.poolRegistry().crossChainDispatcher();
    }

    /***
     * @notice Cross-chain flash debt repayment
     * @dev Not calling `whenNotShutdown` here because nested function already does it
     * @param syntheticToken_ The debt token to repay
     * @param depositToken_ The collateral to withdraw
     * @param withdrawAmount_ The amount to withdraw
     * @param bridgeToken_ The asset that will be bridged out and used to swap for msAsset
     * @param bridgeTokenAmountMin_ The minimum amount out when converting collateral for bridgeToken if they aren't the same (slippage check)
     * @param swapAmountOutMin_ The minimum amount out from the bridgeToken->msAsset swap (slippage check)
     * @param repayAmountMin_ The minimum amount to repay (slippage check)
     * @param lzArgs_ The LayerZero params (See: `Quoter.getFlashRepaySwapAndCallbackLzArgs()`)
     */
    function crossChainFlashRepay(
        ISyntheticToken syntheticToken_,
        IDepositToken depositToken_,
        uint256 withdrawAmount_,
        IERC20 bridgeToken_,
        uint256 bridgeTokenAmountMin_,
        uint256 swapAmountOutMin_,
        uint256 repayAmountMin_,
        bytes calldata lzArgs_
    )
        external
        payable
        override
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
    {
        if (withdrawAmount_ == 0) revert AmountIsZero();

        ICrossChainDispatcher _crossChainDispatcher;
        {
            IDebtToken _debtToken = pool.debtTokenOf(syntheticToken_);
            _debtToken.accrueInterest();
            if (repayAmountMin_ > _debtToken.balanceOf(msg.sender)) revert AmountIsTooHigh();

            _crossChainDispatcher = crossChainDispatcher();
        }

        uint256 _amountIn;
        {
            // 1. withdraw collateral
            // Note: No need to check healthy because this function ensures withdrawing only from unlocked balance
            (_amountIn, ) = depositToken_.withdrawFrom(msg.sender, withdrawAmount_);

            // 2. swap collateral for bridge token
            _amountIn = _swap({
                swapper_: swapper(),
                tokenIn_: _collateralOf(depositToken_),
                tokenOut_: bridgeToken_,
                amountIn_: _amountIn,
                amountOutMin_: bridgeTokenAmountMin_,
                to_: address(_crossChainDispatcher)
            });
        }

        // 3. store request and trigger swap
        _triggerFlashRepaySwap({
            crossChainDispatcher_: _crossChainDispatcher,
            tokenIn_: bridgeToken_,
            tokenOut_: syntheticToken_,
            amountIn_: _amountIn,
            swapAmountOutMin_: swapAmountOutMin_,
            repayAmountMin_: repayAmountMin_,
            lzArgs_: lzArgs_
        });
    }

    /**
     * @dev Stores flash repay cross-chain request and triggers swap on the destination chain
     */
    function _triggerFlashRepaySwap(
        ICrossChainDispatcher crossChainDispatcher_,
        IERC20 tokenIn_,
        ISyntheticToken tokenOut_,
        uint256 amountIn_,
        uint256 swapAmountOutMin_,
        uint256 repayAmountMin_,
        bytes calldata lzArgs_
    ) private {
        uint256 _id = _nextCrossChainRequestId();

        (uint16 _dstChainId, , ) = CrossChainLib.decodeLzArgs(lzArgs_);

        crossChainFlashRepays[_id] = CrossChainFlashRepay({
            dstChainId: _dstChainId,
            syntheticToken: tokenOut_,
            repayAmountMin: repayAmountMin_,
            account: msg.sender,
            finished: false
        });

        crossChainDispatcher_.triggerFlashRepaySwap{value: msg.value}({
            id_: _id,
            account_: payable(msg.sender),
            tokenIn_: address(tokenIn_),
            tokenOut_: address(tokenOut_),
            amountIn_: amountIn_,
            amountOutMin_: swapAmountOutMin_,
            lzArgs_: lzArgs_
        });

        emit CrossChainFlashRepayStarted(_id);
    }

    /**
     * @notice Finalize cross-chain flash debt repayment process
     * @dev Receives msAsset from L1 and use it to repay
     * @param id_ The id of the request
     * @param swapAmountOut_ The msAsset amount received from L1 swap
     * @return _repaid The debt amount repaid
     */
    function crossChainFlashRepayCallback(
        uint256 id_,
        uint256 swapAmountOut_
    ) external override whenNotShutdown nonReentrant onlyIfCrossChainDispatcher returns (uint256 _repaid) {
        CrossChainFlashRepay memory _request = crossChainFlashRepays[id_];

        if (_request.account == address(0)) revert CrossChainRequestInvalidKey();
        if (_request.finished) revert CrossChainRequestCompletedAlready();

        // 1. update state
        crossChainFlashRepays[id_].finished = true;

        // 2. transfer synthetic token
        swapAmountOut_ = _safeTransferFrom(_request.syntheticToken, msg.sender, swapAmountOut_);

        // 3. repay debt
        (_repaid, ) = pool.debtTokenOf(_request.syntheticToken).repay(_request.account, swapAmountOut_);
        if (_repaid < _request.repayAmountMin) revert FlashRepaySlippageTooHigh();

        emit CrossChainFlashRepayFinished(id_);
    }

    /***
     * @notice Cross-chain Leverage
     * @dev Not calling `whenNotShutdown` here because nested function already does it
     * @param tokenIn_ The asset to deposit and that'll be bridged in after swapping from msAsset
     * @param depositToken_ The collateral to deposit
     * @param syntheticToken_ The msAsset to mint
     * @param amountIn_ The amount to deposit
     * @param leverage_ The leverage X param (e.g. 1.5e18 for 1.5X)
     * @param swapAmountOutMin_ The minimum amount out from msAsset->bridgeToken swap (slippage check)
     * @param depositAmountMin_ The minimum final amount to deposit (slippage check)
     * @param lzArgs_ The LayerZero params (See: `Quoter.getLeverageSwapAndCallbackLzArgs()`)
     */
    function crossChainLeverage(
        IERC20 tokenIn_,
        IDepositToken depositToken_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_,
        uint256 swapAmountOutMin_,
        uint256 depositAmountMin_,
        bytes calldata lzArgs_
    )
        external
        payable
        override
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
    {
        IERC20 _tokenIn = tokenIn_; // stack too deep

        if (amountIn_ == 0) revert AmountIsZero();
        if (leverage_ <= 1e18) revert LeverageTooLow();
        if (leverage_ > uint256(1e18).wadDiv(1e18 - depositToken_.collateralFactor())) revert LeverageTooHigh();
        if (address(_tokenIn) == address(0)) revert TokenInIsNull();

        uint256 _debtAmount;
        uint256 _issued;
        {
            // 1. deposit tokenIn
            amountIn_ = _safeTransferFrom(_tokenIn, msg.sender, amountIn_);

            // 2. mint synth
            _debtAmount = _calculateLeverageDebtAmount(_tokenIn, syntheticToken_, amountIn_, leverage_);
            (_issued, ) = pool.debtTokenOf(syntheticToken_).flashIssue(address(crossChainDispatcher()), _debtAmount);
        }

        // 3. store request and trigger swap
        _triggerCrossChainLeverageSwap({
            depositToken_: depositToken_,
            depositedAmount_: amountIn_,
            debtAmount_: _debtAmount,
            tokenIn_: syntheticToken_,
            tokenOut_: _tokenIn,
            swapAmountIn_: _issued,
            swapAmountOutMin_: swapAmountOutMin_,
            depositAmountMin_: depositAmountMin_,
            lzArgs_: lzArgs_
        });
    }

    /**
     * @dev Stores leverage cross-chain request and triggers swap on the destination chain
     */
    function _triggerCrossChainLeverageSwap(
        IDepositToken depositToken_,
        uint256 depositedAmount_,
        uint256 debtAmount_,
        ISyntheticToken tokenIn_,
        IERC20 tokenOut_,
        uint256 swapAmountIn_,
        uint256 swapAmountOutMin_,
        uint256 depositAmountMin_,
        bytes calldata lzArgs_
    ) private {
        uint256 _id = _nextCrossChainRequestId();

        {
            (uint16 _dstChainId, , ) = CrossChainLib.decodeLzArgs(lzArgs_);

            crossChainLeverages[_id] = CrossChainLeverage({
                dstChainId: _dstChainId,
                bridgeToken: tokenOut_,
                depositToken: depositToken_,
                syntheticToken: tokenIn_,
                depositAmountMin: depositAmountMin_,
                bridgeTokenAmountIn: depositedAmount_,
                debtAmount: debtAmount_,
                account: msg.sender,
                finished: false
            });
        }

        crossChainDispatcher().triggerLeverageSwap{value: msg.value}({
            id_: _id,
            account_: payable(msg.sender),
            tokenIn_: address(tokenIn_),
            tokenOut_: address(tokenOut_),
            amountIn_: swapAmountIn_,
            amountOutMin: swapAmountOutMin_,
            lzArgs_: lzArgs_
        });

        emit CrossChainLeverageStarted(_id);
    }

    /**
     * @notice Finalize cross-chain leverage process
     * @dev Receives bridged token (aka naked token) use it to deposit
     * @param id_ The id of the request
     * @param swapAmountOut_ The amount received from swap
     * @return _deposited The amount deposited
     */
    function crossChainLeverageCallback(
        uint256 id_,
        uint256 swapAmountOut_
    ) external override whenNotShutdown nonReentrant onlyIfCrossChainDispatcher returns (uint256 _deposited) {
        CrossChainLeverage memory _request = crossChainLeverages[id_];

        if (_request.account == address(0)) revert CrossChainRequestInvalidKey();
        if (_request.finished) revert CrossChainRequestCompletedAlready();
        IERC20 _collateral = _collateralOf(_request.depositToken);

        // 1. update state
        crossChainLeverages[id_].finished = true;

        // 2. transfer swap's tokenOut (aka bridged token)
        swapAmountOut_ = _safeTransferFrom(_request.bridgeToken, msg.sender, swapAmountOut_);

        // 3. swap bridged token for collateral if needed
        uint256 _bridgeTokenAmount = _request.bridgeTokenAmountIn + swapAmountOut_;
        uint256 _depositAmount = _request.bridgeToken == _collateral
            ? _bridgeTokenAmount
            : _swap(swapper(), _request.bridgeToken, _collateral, _bridgeTokenAmount, 0);
        if (_depositAmount < _request.depositAmountMin) revert LeverageSlippageTooHigh();

        // 4. deposit collateral
        _collateral.safeApprove(address(_request.depositToken), 0);
        _collateral.safeApprove(address(_request.depositToken), _depositAmount);
        (_deposited, ) = _request.depositToken.deposit(_depositAmount, _request.account);

        // 5. mint debt
        IPool _pool = pool;
        _pool.debtTokenOf(_request.syntheticToken).mint(_request.account, _request.debtAmount);

        // 6. check the health of the outcome position
        (bool _isHealthy, , , , ) = _pool.debtPositionOf(_request.account);
        if (!_isHealthy) revert PositionIsNotHealthy();

        emit CrossChainLeverageFinished(id_);
    }

    /**
     * @notice Flash debt repayment
     * @param syntheticToken_ The debt token to repay
     * @param depositToken_ The collateral to withdraw
     * @param withdrawAmount_ The amount to withdraw
     * @param repayAmountMin_ The minimum amount to repay (slippage check)
     */
    function flashRepay(
        ISyntheticToken syntheticToken_,
        IDepositToken depositToken_,
        uint256 withdrawAmount_,
        uint256 repayAmountMin_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
        returns (uint256 _withdrawn, uint256 _repaid)
    {
        if (withdrawAmount_ == 0) revert AmountIsZero();
        if (withdrawAmount_ > depositToken_.balanceOf(msg.sender)) revert AmountIsTooHigh();
        IPool _pool = pool;
        IDebtToken _debtToken = _pool.debtTokenOf(syntheticToken_);
        if (repayAmountMin_ > _debtToken.balanceOf(msg.sender)) revert AmountIsTooHigh();

        // 1. withdraw collateral
        (_withdrawn, ) = depositToken_.flashWithdraw(msg.sender, withdrawAmount_);

        // 2. swap it for synth
        uint256 _amountToRepay = _swap(swapper(), _collateralOf(depositToken_), syntheticToken_, _withdrawn, 0);

        // 3. repay debt
        (_repaid, ) = _debtToken.repay(msg.sender, _amountToRepay);
        if (_repaid < repayAmountMin_) revert FlashRepaySlippageTooHigh();

        // 4. check the health of the outcome position
        (bool _isHealthy, , , , ) = _pool.debtPositionOf(msg.sender);
        if (!_isHealthy) revert PositionIsNotHealthy();

        emit FlashRepaid(syntheticToken_, depositToken_, _withdrawn, _repaid);
    }

    /**
     * @notice Leverage yield position
     * @param tokenIn_ The token to transfer
     * @param depositToken_ The collateral to deposit
     * @param syntheticToken_ The msAsset to mint
     * @param amountIn_ The amount to deposit
     * @param leverage_ The leverage X param (e.g. 1.5e18 for 1.5X)
     * @param depositAmountMin_ The min final deposit amount (slippage)
     */
    function leverage(
        IERC20 tokenIn_,
        IDepositToken depositToken_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_,
        uint256 depositAmountMin_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
        returns (uint256 _deposited, uint256 _issued)
    {
        if (amountIn_ == 0) revert AmountIsZero();
        if (leverage_ <= 1e18) revert LeverageTooLow();
        if (leverage_ > uint256(1e18).wadDiv(1e18 - depositToken_.collateralFactor())) revert LeverageTooHigh();

        ISwapper _swapper = swapper();

        // 1. transfer collateral
        IERC20 _collateral = _collateralOf(depositToken_);
        if (address(tokenIn_) == address(0)) tokenIn_ = _collateral;
        amountIn_ = _safeTransferFrom(tokenIn_, msg.sender, amountIn_);
        if (tokenIn_ != _collateral) {
            // Note: `amountOutMin_` is `0` because slippage will be checked later on
            amountIn_ = _swap(_swapper, tokenIn_, _collateral, amountIn_, 0);
        }

        {
            // 2. mint synth + debt
            uint256 _debtAmount = _calculateLeverageDebtAmount(_collateral, syntheticToken_, amountIn_, leverage_);
            IDebtToken _debtToken = pool.debtTokenOf(syntheticToken_);
            (_issued, ) = _debtToken.flashIssue(address(this), _debtAmount);
            _debtToken.mint(msg.sender, _debtAmount);
        }

        // 3. swap synth for collateral
        uint256 _depositAmount = amountIn_ + _swap(_swapper, syntheticToken_, _collateral, _issued, 0);
        if (_depositAmount < depositAmountMin_) revert LeverageSlippageTooHigh();

        // 4. deposit collateral
        _collateral.safeApprove(address(depositToken_), 0);
        _collateral.safeApprove(address(depositToken_), _depositAmount);
        (_deposited, ) = depositToken_.deposit(_depositAmount, msg.sender);

        // 5. check the health of the outcome position
        (bool _isHealthy, , , , ) = pool.debtPositionOf(msg.sender);
        if (!_isHealthy) revert PositionIsNotHealthy();

        emit Leveraged(tokenIn_, depositToken_, syntheticToken_, leverage_, amountIn_, _issued, _deposited);
    }

    /**
     * @notice Retry cross-chain flash repay callback
     * @dev This function is used to recover from callback failures due to slippage
     * @param id_ The id of the request
     * @param newRepayAmountMin_ Updated slippage check param
     * @param srcChainId_ The source chain of failed tx
     * @param srcAddress_ The source path of failed tx
     * @param nonce_ The nonce of failed tx
     * @param amount_ The amount of failed tx
     * @param payload_ The payload of failed tx
     */
    function retryCrossChainFlashRepayCallback(
        uint256 id_,
        uint256 newRepayAmountMin_,
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        uint amount_,
        bytes calldata payload_
    ) external {
        CrossChainFlashRepay memory _request = crossChainFlashRepays[id_];

        if (_request.account == address(0)) revert CrossChainRequestInvalidKey();
        if (msg.sender != _request.account) revert SenderIsNotAccount();
        if (_request.finished) revert CrossChainRequestCompletedAlready();

        crossChainFlashRepays[id_].repayAmountMin = newRepayAmountMin_;

        ICrossChainDispatcher _crossChainDispatcher = crossChainDispatcher();
        bytes memory _from = abi.encodePacked(_crossChainDispatcher.crossChainDispatcherOf(srcChainId_));

        _request.syntheticToken.proxyOFT().retryOFTReceived({
            _srcChainId: srcChainId_,
            _srcAddress: srcAddress_,
            _nonce: nonce_,
            _from: _from,
            _to: address(_crossChainDispatcher),
            _amount: amount_,
            _payload: payload_
        });
    }

    /**
     * @notice Retry cross-chain leverage callback
     * @dev This function is used to recover from callback failures due to slippage
     * @param id_ The id of the request
     * @param newDepositAmountMin_ Updated slippage check param
     * @param srcChainId_ The source chain of failed tx
     * @param srcAddress_ The source path of failed tx
     * @param nonce_ The nonce of failed tx
     */
    function retryCrossChainLeverageCallback(
        uint256 id_,
        uint256 newDepositAmountMin_,
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint256 nonce_
    ) external {
        CrossChainLeverage memory _request = crossChainLeverages[id_];

        if (_request.account == address(0)) revert CrossChainRequestInvalidKey();
        if (msg.sender != _request.account) revert SenderIsNotAccount();
        if (_request.finished) revert CrossChainRequestCompletedAlready();

        crossChainLeverages[id_].depositAmountMin = newDepositAmountMin_;

        crossChainDispatcher().stargateComposer().stargateRouter().clearCachedSwap(srcChainId_, srcAddress_, nonce_);
    }

    /**
     * @notice Get the swapper contract
     */
    function swapper() public view returns (ISwapper _swapper) {
        return pool.poolRegistry().swapper();
    }

    /**
     * @notice Calculate debt to issue for a leverage operation
     * @param collateral_ The collateral to deposit
     * @param syntheticToken_ The msAsset to mint
     * @param amountIn_ The amount to deposit
     * @param leverage_ The leverage X param (e.g. 1.5e18 for 1.5X)
     * @return _debtAmount The debt issue
     */
    function _calculateLeverageDebtAmount(
        IERC20 collateral_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_
    ) private view returns (uint256 _debtAmount) {
        return
            pool.masterOracle().quote(
                address(collateral_),
                address(syntheticToken_),
                (leverage_ - 1e18).wadMul(amountIn_)
            );
    }

    /**
     * @dev `collateral` is a better name than `underlying`
     * See more: https://github.com/autonomoussoftware/metronome-synth/issues/905
     */
    function _collateralOf(IDepositToken depositToken_) private view returns (IERC20) {
        return depositToken_.underlying();
    }

    /**
     * @dev Generates cross-chain request id by hashing `chainId`+`requestId` in order to avoid
     * having same id across supported chains
     * Note: The cross-chain code mostly uses LZ chain ids but in this case, we're using native id.
     */
    function _nextCrossChainRequestId() private returns (uint256 _id) {
        return uint256(keccak256(abi.encode(block.chainid, ++crossChainRequestsLength)));
    }

    /**
     * @notice Transfer token and check actual amount transferred
     * @param token_ The token to transfer
     * @param from_ The account to get tokens from
     * @param amount_ The amount to transfer
     * @return _transferred The actual transferred amount
     */
    function _safeTransferFrom(IERC20 token_, address from_, uint256 amount_) private returns (uint256 _transferred) {
        uint256 _before = token_.balanceOf(address(this));
        token_.safeTransferFrom(from_, address(this), amount_);
        return token_.balanceOf(address(this)) - _before;
    }

    /**
     * @notice Swap assets using Swapper contract
     * @dev Use `address(this)` as amount out receiver
     * @param swapper_ The Swapper contract
     * @param tokenIn_ The token to swap from
     * @param tokenOut_ The token to swap to
     * @param amountIn_ The amount in
     * @param amountOutMin_ The minimum amount out (slippage check)
     * @return _amountOut The actual amount out
     */
    function _swap(
        ISwapper swapper_,
        IERC20 tokenIn_,
        IERC20 tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_
    ) private returns (uint256 _amountOut) {
        return _swap(swapper_, tokenIn_, tokenOut_, amountIn_, amountOutMin_, address(this));
    }

    /**
     * @notice Swap assets using Swapper contract
     * @param swapper_ The Swapper contract
     * @param tokenIn_ The token to swap from
     * @param tokenOut_ The token to swap to
     * @param amountIn_ The amount in
     * @param amountOutMin_ The minimum amount out (slippage check)
     * @param to_ The amount out receiver
     * @return _amountOut The actual amount out
     */
    function _swap(
        ISwapper swapper_,
        IERC20 tokenIn_,
        IERC20 tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address to_
    ) private returns (uint256 _amountOut) {
        if (tokenIn_ != tokenOut_) {
            tokenIn_.safeApprove(address(swapper_), 0);
            tokenIn_.safeApprove(address(swapper_), amountIn_);
            uint256 _tokenOutBefore = tokenOut_.balanceOf(to_);
            swapper_.swapExactInput(address(tokenIn_), address(tokenOut_), amountIn_, amountOutMin_, to_);
            return tokenOut_.balanceOf(to_) - _tokenOutBefore;
        } else if (to_ != address(this)) {
            tokenIn_.safeTransfer(to_, amountIn_);
        }
        return amountIn_;
    }
}

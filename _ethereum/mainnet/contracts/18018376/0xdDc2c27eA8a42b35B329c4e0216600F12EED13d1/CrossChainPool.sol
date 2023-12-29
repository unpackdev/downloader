// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./HighCovRatioFeePoolV3.sol";
import "./IAdaptor.sol";
import "./ICrossChainPool.sol";

/**
 * @title Mega Pool
 * @notice Mega Pool is able to handle cross-chain swaps in addition to ordinary swap within its own chain
 * @dev Refer to note of `swapTokensForTokensCrossChain` for procedure of a cross-chain swap
 * Note: All variables are 18 decimals, except from that of parameters of external functions and underlying tokens
 */
contract CrossChainPool is HighCovRatioFeePoolV3, ICrossChainPool {
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;
    using SignedSafeMath for uint256;

    /**
     * Storage
     */

    IAdaptor public adaptor;
    bool public swapCreditForTokensEnabled;
    bool public swapTokensForCreditEnabled;

    uint128 public creditForTokensHaircut;
    uint128 public tokensForCreditHaircut;

    uint128 public totalCreditMinted;
    uint128 public totalCreditBurned;

    /// @notice the maximum allowed amount of net mint credit. `totalCreditMinted - totalCreditBurned` should be smaller than this value
    uint128 public maximumOutboundCredit; // Upper limit of net minted credit
    uint128 public maximumInboundCredit; // Upper limit of net burned credit

    mapping(address => uint256) public creditBalance;

    uint256[50] private __gap;

    /**
     * Errors
     */

    error WOMBAT_ZERO_CREDIT_AMOUNT();

    /**
     * Events
     */

    /**
     * @notice Event that is emitted when token is swapped into credit
     */
    event SwapTokensForCredit(
        address indexed sender,
        address indexed fromToken,
        uint256 fromAmount,
        uint256 fromTokenFee,
        uint256 creditAmount
    );

    /**
     * @notice Event that is emitted when credit is swapped into token
     */
    event SwapCreditForTokens(
        uint256 creditAmount,
        address indexed toToken,
        uint256 toAmount,
        uint256 toTokenFee,
        address indexed receiver
    );

    event MintCredit(address indexed receiver, uint256 creditAmount);

    /**
     * Errors
     */

    error POOL__CREDIT_NOT_ENOUGH();
    error POOL__REACH_MAXIMUM_MINTED_CREDIT();
    error POOL__REACH_MAXIMUM_BURNED_CREDIT();
    error POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
    error POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();

    /**
     * External/public functions
     */

    /**
     * @dev refer to documentation in the interface
     */
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 creditAmount, uint256 fromTokenFee, uint256 sequence)
    {
        // Assumption: the adaptor should check `toChain` and `toToken`
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();
        requireAssetNotPaused(fromToken);
        _checkAddress(receiver);

        IAsset fromAsset = _assetOf(fromToken);
        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);

        (creditAmount, fromTokenFee) = _swapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            minimumCreditAmount
        );
        if (creditAmount == 0) revert WOMBAT_ZERO_CREDIT_AMOUNT();

        fromTokenFee = fromTokenFee.fromWad(fromAsset.underlyingTokenDecimals());
        emit SwapTokensForCredit(msg.sender, fromToken, fromAmount, fromTokenFee, creditAmount);

        // Wormhole: computeBudget + applicationBudget + wormholeFee should equal the msg.value
        sequence = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            creditAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );
    }

    /**
     * @dev refer to documentation in the interface
     */
    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 toTokenFee) {
        _beforeSwapCreditForTokens(fromAmount, receiver);
        (actualToAmount, toTokenFee) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver);
    }

    /**
     * @dev refer to documentation in the interface
     */
    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) external payable override nonReentrant whenNotPaused returns (uint256 trackingId) {
        _beforeSwapCreditForTokens(fromAmount, receiver);

        // Wormhole: computeBudget + applicationBudget + wormholeFee should equal the msg.value
        trackingId = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            fromAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );
    }

    /**
     * Internal functions
     */

    function _onlyAdaptor() internal view {
        if (msg.sender != address(adaptor)) revert WOMBAT_FORBIDDEN();
    }

    function _swapTokensForCredit(
        IAsset fromAsset,
        uint256 fromAmount,
        uint256 minimumCreditAmount
    ) internal returns (uint256 creditAmount, uint256 fromTokenFee) {
        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, fromTokenFee) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount,
            ampFactor,
            WAD,
            tokensForCreditHaircut,
            startCovRatio,
            endCovRatio
        );

        _checkAmount(minimumCreditAmount, creditAmount);

        fromAsset.addCash(fromAmount - fromTokenFee);
        totalCreditMinted += _to128(creditAmount);
        _feeCollected[fromAsset] += fromTokenFee; // unlike other swaps, fee is collected in from token

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted > maximumOutboundCredit + totalCreditBurned) revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    function _beforeSwapCreditForTokens(uint256 fromAmount, address receiver) internal {
        _checkAddress(receiver);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        if (creditBalance[msg.sender] < fromAmount) revert POOL__CREDIT_NOT_ENOUGH();
        unchecked {
            creditBalance[msg.sender] -= fromAmount;
        }
    }

    function _doSwapCreditForTokens(
        address toToken,
        uint256 fromCreditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal returns (uint256 actualToAmount, uint256 toTokenFee) {
        if (fromCreditAmount == 0) revert WOMBAT_ZERO_CREDIT_AMOUNT();

        IAsset toAsset = _assetOf(toToken);
        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        (actualToAmount, toTokenFee) = _swapCreditForTokens(
            toAsset,
            fromCreditAmount,
            minimumToAmount.toWad(toDecimal)
        );
        actualToAmount = actualToAmount.fromWad(toDecimal);
        toTokenFee = toTokenFee.fromWad(toDecimal);

        toAsset.transferUnderlyingToken(receiver, actualToAmount);
        totalCreditBurned += _to128(fromCreditAmount);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned > maximumInboundCredit + totalCreditMinted) revert POOL__REACH_MAXIMUM_BURNED_CREDIT();

        emit SwapCreditForTokens(fromCreditAmount, toToken, actualToAmount, toTokenFee, receiver);
    }

    function _swapCreditForTokens(
        IAsset toAsset,
        uint256 fromCreditAmount,
        uint256 minimumToAmount
    ) internal returns (uint256 actualToAmount, uint256 toTokenFee) {
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: If we want to support dynamic asset (aka volatile / rather-volatile pools), implement `_quoteFactor` for credit
        (actualToAmount, toTokenFee) = CoreV3.quoteSwapCreditForTokens(
            fromCreditAmount,
            toAsset,
            ampFactor,
            WAD,
            creditForTokensHaircut
        );

        _checkAmount(minimumToAmount, actualToAmount);
        _feeCollected[toAsset] += toTokenFee;

        // fee is removed from cash to maintain r* = 1. It is distributed during _mintFee()
        toAsset.removeCash(actualToAmount + toTokenFee);

        // revert if cov ratio < 1% to avoid precision error
        if (DSMath.wdiv(toAsset.cash(), toAsset.liability()) < WAD / 100) revert WOMBAT_FORBIDDEN();
    }

    /**
     * Read-only functions
     */

    function quoteSwapCreditForTokens(
        address toToken,
        uint256 fromCreditAmount
    ) external view returns (uint256 actualToAmount, uint256 toTokenFee) {
        IAsset toAsset = _assetOf(toToken);
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        (actualToAmount, toTokenFee) = CoreV3.quoteSwapCreditForTokens(
            fromCreditAmount,
            toAsset,
            ampFactor,
            WAD,
            creditForTokensHaircut
        );

        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        actualToAmount = actualToAmount.fromWad(toDecimal);
        toTokenFee = toTokenFee.fromWad(toDecimal);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned + fromCreditAmount > maximumInboundCredit + totalCreditMinted)
            revert POOL__REACH_MAXIMUM_BURNED_CREDIT();
    }

    function quoteSwapTokensForCredit(
        address fromToken,
        uint256 fromAmount
    ) external view returns (uint256 creditAmount, uint256 fromTokenFee) {
        IAsset fromAsset = _assetOf(fromToken);

        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, fromTokenFee) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            ampFactor,
            WAD,
            tokensForCreditHaircut,
            startCovRatio,
            endCovRatio
        );

        fromTokenFee = fromTokenFee.fromWad(fromAsset.underlyingTokenDecimals());

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted + creditAmount > maximumOutboundCredit + totalCreditBurned)
            revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    /**
     * @notice Calculate the r* and invariant when all credits are settled
     */
    function globalEquilCovRatioWithCredit() external view returns (uint256 equilCovRatio, uint256 invariantInUint) {
        int256 invariant;
        int256 SL;
        (invariant, SL) = _globalInvariantFunc();
        // oustanding credit = totalCreditBurned - totalCreditMinted
        int256 creditOffset = (int256(uint256(totalCreditBurned)) - int256(uint256(totalCreditMinted))).wmul(
            (WAD + ampFactor).toInt256()
        );
        invariant += creditOffset;
        equilCovRatio = uint256(CoreV3.equilCovRatio(invariant, SL, ampFactor.toInt256()));
        invariantInUint = uint256(invariant);
    }

    function _to128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
    }

    /**
     * Permisioneed functions
     */

    /**
     * @dev refer to documentation in the interface
     */
    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external override whenNotPaused returns (uint256 actualToAmount, uint256 toTokenFee) {
        _onlyAdaptor();
        // Note: `_checkAddress(receiver)` could be skipped at it is called at the `fromChain`
        (actualToAmount, toTokenFee) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver);
    }

    /**
     * @notice In case `completeSwapCreditForTokens` fails, adaptor should mint credit to the respective user
     * @dev This function is only for the case when `completeSwapCreditForTokens` fails, and should not be called otherwise
     * Also, this function should work even if the pool is paused
     */
    function mintCredit(uint256 creditAmount, address receiver) external override {
        _onlyAdaptor();
        creditBalance[receiver] += creditAmount;
        emit MintCredit(receiver, creditAmount);
    }

    function setSwapTokensForCreditEnabled(bool enable) external onlyOwner {
        swapTokensForCreditEnabled = enable;
    }

    function setSwapCreditForTokensEnabled(bool enable) external onlyOwner {
        swapCreditForTokensEnabled = enable;
    }

    function setMaximumOutboundCredit(uint128 _maximumOutboundCredit) external onlyOwner {
        maximumOutboundCredit = _maximumOutboundCredit;
    }

    function setMaximumInboundCredit(uint128 _maximumInboundCredit) external onlyOwner {
        maximumInboundCredit = _maximumInboundCredit;
    }

    function setAdaptorAddr(IAdaptor _adaptor) external onlyOwner {
        adaptor = _adaptor;
    }

    function setCrossChainHaircut(uint128 _tokensForCreditHaircut, uint128 _creditForTokensHaircut) external onlyOwner {
        require(_creditForTokensHaircut < 1e18 && _tokensForCreditHaircut < 1e18);
        creditForTokensHaircut = _creditForTokensHaircut;
        tokensForCreditHaircut = _tokensForCreditHaircut;
    }
}

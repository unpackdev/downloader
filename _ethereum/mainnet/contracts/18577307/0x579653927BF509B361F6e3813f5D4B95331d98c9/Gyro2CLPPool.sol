// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// import "./FixedPoint.sol";
import "./GyroFixedPoint.sol";

import "./WeightedPoolUserDataHelpers.sol";
import "./WeightedPool2TokensMiscData.sol";
import "./IRateProvider.sol";

import "./GyroConfigKeys.sol";
import "./GyroConfigHelpers.sol";
import "./IGyroConfig.sol";
import "./GyroPoolMath.sol";
import "./GyroErrors.sol";

import "./CappedLiquidity.sol";
import "./LocallyPausable.sol";
import "./ExtensibleWeightedPool2Tokens.sol";
import "./Gyro2CLPPoolErrors.sol";
import "./Gyro2CLPMath.sol";

contract Gyro2CLPPool is ExtensibleWeightedPool2Tokens, CappedLiquidity, LocallyPausable {
    using GyroFixedPoint for uint256;
    using WeightedPoolUserDataHelpers for bytes;
    using WeightedPool2TokensMiscData for bytes32;
    using GyroConfigHelpers for IGyroConfig;

    uint256 private immutable _sqrtAlpha;
    uint256 private immutable _sqrtBeta;
    bytes32 private constant POOL_TYPE = "2CLP";

    IGyroConfig public gyroConfig;

    /// @dev for rate scaling
    IRateProvider public immutable rateProvider0;
    IRateProvider public immutable rateProvider1;

    struct GyroParams {
        NewPoolParams baseParams;
        uint256 sqrtAlpha; // A: Should already be upscaled
        uint256 sqrtBeta; // A: Should already be upscaled. Could be passed as an array[](2)
        address rateProvider0;
        address rateProvider1;
        address capManager;
        CapParams capParams;
        address pauseManager;
    }

    constructor(GyroParams memory params, address configAddress)
        ExtensibleWeightedPool2Tokens(params.baseParams)
        CappedLiquidity(params.capManager, params.capParams)
        LocallyPausable(params.pauseManager)
    {
        _grequire(params.sqrtAlpha < params.sqrtBeta, Gyro2CLPPoolErrors.SQRT_PARAMS_WRONG);
        _grequire(configAddress != address(0), GyroErrors.ZERO_ADDRESS);
        _sqrtAlpha = params.sqrtAlpha;
        _sqrtBeta = params.sqrtBeta;

        gyroConfig = IGyroConfig(configAddress);

        rateProvider0 = IRateProvider(params.rateProvider0);
        rateProvider1 = IRateProvider(params.rateProvider1);
    }

    /// @dev Returns sqrtAlpha and sqrtBeta (square roots of lower and upper price bounds of p_x respectively)
    function getSqrtParameters() external view returns (uint256[2] memory) {
        return _sqrtParameters();
    }

    function _sqrtParameters() internal view virtual returns (uint256[2] memory virtualParameters) {
        virtualParameters[0] = _sqrtParameters(true);
        virtualParameters[1] = _sqrtParameters(false);
        return virtualParameters;
    }

    function _sqrtParameters(bool parameter0) internal view virtual returns (uint256) {
        return parameter0 ? _sqrtAlpha : _sqrtBeta;
    }

    /** @dev Reads the balance of a token from the balancer vault and returns the scaled amount. Smaller storage access
     * compared to getVault().getPoolTokens().
     * Copied from the 3CLP *except* that for the 2CLP, the scalingFactor is interpreted as a regular integer, not a
     * FixedPoint number. This is an inconsistency between the base contracts.
     */
    function _getScaledTokenBalance(IERC20 token, uint256 scalingFactor) internal view returns (uint256 balance) {
        // Signature of getPoolTokenInfo(): (pool id, token) -> (cash, managed, lastChangeBlock, assetManager)
        // and total amount = cash + managed. See balancer repo, PoolTokens.sol and BalanceAllocation.sol
        (uint256 cash, uint256 managed, , ) = getVault().getPoolTokenInfo(getPoolId(), token);
        balance = cash + managed; // can't overflow, see BalanceAllocation.sol::total() in the Balancer repo.
        balance = balance.mulDown(scalingFactor);
    }

    /** @dev Get all balances in the pool, scaled by the appropriate scaling factors, in a relatively gas-efficient way.
     * Essentially copied from the 3CLP.
     */
    function _getAllBalances() internal view returns (uint256[] memory balances) {
        // The below is more gas-efficient than the following line because the token slots don't have to be read in the
        // vault.
        // (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());
        balances = new uint256[](2);
        balances[0] = _getScaledTokenBalance(_token0, _scalingFactor(true));
        balances[1] = _getScaledTokenBalance(_token1, _scalingFactor(false));
        return balances;
    }

    /// @dev Returns virtual offsets a and b for reserves x and y respectively, as in (x+a)*(y+b)=L^2
    function getVirtualParameters() external view returns (uint256[] memory virtualParams) {
        uint256[] memory balances = _getAllBalances();
        // _calculateCurrentValues() is defined in terms of an in/out pair, but we just map this to the 0/1 (x/y) pair.
        virtualParams = new uint256[](2);
        (, virtualParams[0], virtualParams[1]) = _calculateCurrentValues(balances[0], balances[1], true);
    }

    function _getVirtualParameters(uint256[2] memory sqrtParams, uint256 invariant)
        internal
        view
        virtual
        returns (uint256[2] memory virtualParameters)
    {
        virtualParameters[0] = _virtualParameters(true, sqrtParams[1], invariant);
        virtualParameters[1] = _virtualParameters(false, sqrtParams[0], invariant);
        return virtualParameters;
    }

    function _virtualParameters(
        bool parameter0,
        uint256 sqrtParam,
        uint256 invariant
    ) internal view virtual returns (uint256) {
        return
            parameter0
                ? (Gyro2CLPMath._calculateVirtualParameter0(invariant, sqrtParam))
                : (Gyro2CLPMath._calculateVirtualParameter1(invariant, sqrtParam));
    }

    /**
     * @dev Returns the current value of the invariant.
     */
    function getInvariant() public view override returns (uint256) {
        uint256[] memory balances = _getAllBalances();
        uint256[2] memory sqrtParams = _sqrtParameters();

        return Gyro2CLPMath._calculateInvariant(balances, sqrtParams[0], sqrtParams[1]);
    }

    /** When rateProvider{0,1} is provided, this returns the *scaled* price, suitable to compare *rate scaled* balances.
     *  To compare (decimal- but) not-rate-scaled balances, apply _adjustPrice() to the result.
     */
    function _getPrice(
        uint256[] memory balances,
        uint256 virtualParam0,
        uint256 virtualParam1
    ) internal pure returns (uint256 spotPrice) {
        return Gyro2CLPMath._calcSpotPriceAinB(balances[0], virtualParam0, balances[1], virtualParam1);
    }

    /** Returns the current spot price of token0 quoted in units of token1. When rateProvider{0,1} is provided, the
     * returned price corresponds to tokens *before* rate scaling.
     */
    function getPrice() external view returns (uint256 spotPrice) {
        uint256[] memory balances = _getAllBalances();
        (uint256 invariant, uint256 virtualParam0, uint256 virtualParam1) = _calculateCurrentValues(balances[0], balances[1], true);
        spotPrice = _getPrice(balances, virtualParam0, virtualParam1);
        spotPrice = _adjustPrice(spotPrice);
    }

    // Swap Hooks

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) public virtual override whenNotPaused onlyVault(request.poolId) returns (uint256) {
        bool tokenInIsToken0 = request.tokenIn == _token0;

        uint256 scalingFactorTokenIn = _scalingFactor(tokenInIsToken0);
        uint256 scalingFactorTokenOut = _scalingFactor(!tokenInIsToken0);

        // All token amounts are upscaled.
        balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
        balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);

        // All the calculations in one function to avoid Error Stack Too Deep
        (uint256 currentInvariant, uint256 virtualParamIn, uint256 virtualParamOut) = _calculateCurrentValues(
            balanceTokenIn,
            balanceTokenOut,
            tokenInIsToken0
        );

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // Fees are subtracted before scaling, to reduce the complexity of the rounding direction analysis.
            // This is amount - fee amount, so we round up (favoring a higher fee amount).
            uint256 feeAmount = request.amount.mulUp(getSwapFeePercentage());
            // subtract fee and upscale so request.amount is appropriate for the following pool math.
            request.amount = _upscale(request.amount.sub(feeAmount), scalingFactorTokenIn);

            uint256 amountOut = _onSwapGivenIn(request, balanceTokenIn, balanceTokenOut, virtualParamIn, virtualParamOut);

            // amountOut tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountOut, scalingFactorTokenOut);
        } else {
            request.amount = _upscale(request.amount, scalingFactorTokenOut);

            uint256 amountIn = _onSwapGivenOut(request, balanceTokenIn, balanceTokenOut, virtualParamIn, virtualParamOut);

            // amountIn tokens are entering the Pool, so we round up.
            amountIn = _downscaleUp(amountIn, scalingFactorTokenIn);

            // Fees are added after scaling happens, to reduce the complexity of the rounding direction analysis.
            // This is amount + fee amount, so we round up (favoring a higher fee amount).
            return amountIn.divUp(getSwapFeePercentage().complement());
        }
    }

    // We assume all amounts to be upscaled correctly
    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut,
        uint256 virtualParamIn,
        uint256 virtualParamOut
    ) internal pure override returns (uint256) {
        // NB: Swaps are disabled while the contract is paused.
        return Gyro2CLPMath._calcOutGivenIn(currentBalanceTokenIn, currentBalanceTokenOut, swapRequest.amount, virtualParamIn, virtualParamOut);
    }

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut,
        uint256 virtualParamIn,
        uint256 virtualParamOut
    ) internal pure override returns (uint256) {
        // NB: Swaps are disabled while the contract is paused.
        return Gyro2CLPMath._calcInGivenOut(currentBalanceTokenIn, currentBalanceTokenOut, swapRequest.amount, virtualParamIn, virtualParamOut);
    }

    /// @dev invariant and virtual offsets.
    function calculateCurrentValues(
        uint256 balanceTokenIn, // not scaled
        uint256 balanceTokenOut, // not scaled
        bool tokenInIsToken0
    )
        public
        view
        returns (
            uint256 currentInvariant,
            uint256 virtualParamIn,
            uint256 virtualParamOut
        )
    {
        uint256 scalingFactorTokenIn = _scalingFactor(tokenInIsToken0);
        uint256 scalingFactorTokenOut = _scalingFactor(!tokenInIsToken0);
        balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
        balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);
        return _calculateCurrentValues(balanceTokenIn, balanceTokenOut, tokenInIsToken0);
    }

    function _calculateCurrentValues(
        uint256 balanceTokenIn, // scaled
        uint256 balanceTokenOut, // scaled
        bool tokenInIsToken0
    )
        internal
        view
        returns (
            uint256 currentInvariant,
            uint256 virtualParamIn,
            uint256 virtualParamOut
        )
    {
        uint256[] memory balances = new uint256[](2);
        balances[0] = tokenInIsToken0 ? balanceTokenIn : balanceTokenOut;
        balances[1] = tokenInIsToken0 ? balanceTokenOut : balanceTokenIn;

        uint256[2] memory sqrtParams = _sqrtParameters();

        currentInvariant = Gyro2CLPMath._calculateInvariant(balances, sqrtParams[0], sqrtParams[1]);

        uint256[2] memory virtualParam = _getVirtualParameters(sqrtParams, currentInvariant);

        virtualParamIn = tokenInIsToken0 ? virtualParam[0] : virtualParam[1];
        virtualParamOut = tokenInIsToken0 ? virtualParam[1] : virtualParam[0];
    }

    /**
     * @dev Called when the Pool is joined for the first time; that is, when the BPT total supply is zero.
     *
     * Returns the amount of BPT to mint, and the token amounts the Pool will receive in return.
     *
     * Minted BPT will be sent to `recipient`, except for _MINIMUM_BPT, which will be deducted from this amount and sent
     * to the zero address instead. This will cause that BPT to remain forever locked there, preventing total BPT from
     * ever dropping below that value, and ensuring `_onInitializePool` can only be called once in the entire Pool's
     * lifetime.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     */
    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal override returns (uint256, uint256[] memory) {
        BaseWeightedPool.JoinKind kind = userData.joinKind();
        _require(kind == BaseWeightedPool.JoinKind.INIT, Errors.UNINITIALIZED);

        uint256[] memory amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, 2);
        _upscaleArray(amountsIn);

        (uint256 invariantAfterJoin, uint256 virtualParam0, uint256 virtualParam1) = _calculateCurrentValues(amountsIn[0], amountsIn[1], true);

        /* We initialize the number of BPT tokens such that one BPT token corresponds to one unit of token1 at the initialized pool price. This makes BPT tokens comparable across pools with different parameters. Note that the invariant does *not* have this property!
         */
        uint256 spotPrice = _getPrice(amountsIn, virtualParam0, virtualParam1);
        uint256 bptAmountOut = Math.add(amountsIn[0].mulDown(spotPrice), amountsIn[1]);

        _lastInvariant = invariantAfterJoin;

        return (bptAmountOut, amountsIn);
    }

    /**
     * @dev Called whenever the Pool is joined after the first initialization join (see `_onInitializePool`).
     *
     * Returns the amount of BPT to mint, the token amounts that the Pool will receive in return, and the number of
     * tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * Minted BPT will be sent to `recipient`.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onJoinPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     *
     * protocolSwapFeePercentage argument is intentionally unused as protocol fees are handled in a different way
     *
     */
    function _onJoinPool(
        bytes32,
        address,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256, //protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        // NB Joins are disabled when the pool is paused.

        uint256[2] memory sqrtParams = _sqrtParameters();

        // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous
        // join or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids
        // spending gas accounting for fees on each individual swap.
        uint256 invariantBeforeAction = Gyro2CLPMath._calculateInvariant(balances, sqrtParams[0], sqrtParams[1]);
        uint256[2] memory virtualParam = _getVirtualParameters(sqrtParams, invariantBeforeAction);

        _distributeFees(invariantBeforeAction);

        (uint256 bptAmountOut, uint256[] memory amountsIn) = _doJoin(balances, userData);

        if (_capParams.capEnabled) {
            _ensureCap(bptAmountOut, balanceOf(recipient), totalSupply());
        }

        // Since we pay fees in BPT, they have not changed the invariant and 'invariantBeforeAction' is still consistent
        // with  'balances'. Therefore, we can use a simplified method to update the invariant that does not require a
        // full re-computation.
        // Note: Should this be changed in the future, we also need to reduce the invariant proportionally by the total
        // protocol fee factor.
        _lastInvariant = GyroPoolMath.liquidityInvariantUpdate(invariantBeforeAction, bptAmountOut, totalSupply(), true);

        // returns a new uint256[](2) b/c Balancer vault is expecting a fee array, but fees paid in BPT instead
        return (bptAmountOut, amountsIn, new uint256[](2));
    }

    function _doJoin(uint256[] memory balances, bytes memory userData) internal view returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        BaseWeightedPool.JoinKind kind = userData.joinKind();

        // We do NOT currently support unbalanced update, i.e., EXACT_TOKENS_IN_FOR_BPT_OUT or TOKEN_IN_FOR_EXACT_BPT_OUT
        if (kind == BaseWeightedPool.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT) {
            (bptAmountOut, amountsIn) = _joinAllTokensInForExactBPTOut(balances, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function _joinAllTokensInForExactBPTOut(uint256[] memory balances, bytes memory userData)
        internal
        view
        override
        returns (uint256, uint256[] memory)
    {
        uint256 bptAmountOut = userData.allTokensInForExactBptOut();
        // Note that there is no maximum amountsIn parameter: this is handled by `IVault.joinPool`.

        uint256[] memory amountsIn = GyroPoolMath._calcAllTokensInGivenExactBptOut(balances, bptAmountOut, totalSupply());

        return (bptAmountOut, amountsIn);
    }

    /**
     * @dev Called whenever the Pool is exited.
     *
     * Returns the amount of BPT to burn, the token amounts for each Pool token that the Pool will grant in return, and
     * the number of tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * BPT will be burnt from `sender`.
     *
     * The Pool will grant tokens to `recipient`. These amounts are considered upscaled and will be downscaled
     * (rounding down) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onExitPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     *
     * protocolSwapFeePercentage argument is intentionally unused as protocol fees are handled in a different way
     */
    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256, // protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        // Exits are not completely disabled while the contract is paused: proportional exits (exact BPT in for tokens
        // out) remain functional.

        uint256[2] memory sqrtParams = _sqrtParameters();

        if (_isNotPaused()) {
            // Due protocol swap fee amounts are computed by measuring the growth of the invariant between the previous
            // join or exit event and now - the invariant's growth is due exclusively to swap fees. This avoids
            // spending gas calculating the fees on each individual swap.
            uint256 invariantBeforeAction = Gyro2CLPMath._calculateInvariant(balances, sqrtParams[0], sqrtParams[1]);
            uint256[2] memory virtualParam = _getVirtualParameters(sqrtParams, invariantBeforeAction);

            _distributeFees(invariantBeforeAction);

            (bptAmountIn, amountsOut) = _doExit(balances, userData);

            // Since we pay fees in BPT, they have not changed the invariant and 'invariantBeforeAction' is still
            // consistent with 'balances'. Therefore, we can use a simplified method to update the invariant that does
            // not require a full re-computation.
            // Note: Should this be changed in the future, we also need to reduce the invariant proportionally by the
            // total protocol fee factor.
            _lastInvariant = GyroPoolMath.liquidityInvariantUpdate(invariantBeforeAction, bptAmountIn, totalSupply(), false);
        } else {
            // Note: If the contract is paused, swap protocol fee amounts are not charged
            // to avoid extra calculations and reduce the potential for errors.
            (bptAmountIn, amountsOut) = _doExit(balances, userData);

            // Invalidate _lastInvariant. We do not compute the invariant to reduce the potential for errors or lockup.
            // Instead, we set the invariant such that any following (non-paused) join/exit will ignore and recompute
            // it. (see GyroPoolMath._calcProtocolFees())
            _lastInvariant = type(uint256).max;
        }

        // returns a new uint256[](2) b/c Balancer vault is expecting a fee array, but fees paid in BPT instead
        return (bptAmountIn, amountsOut, new uint256[](2));
    }

    function _doExit(uint256[] memory balances, bytes memory userData) internal view returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        BaseWeightedPool.ExitKind kind = userData.exitKind();

        // We do NOT support unbalanced exit at the moment, i.e., EXACT_BPT_IN_FOR_ONE_TOKEN_OUT or
        // BPT_IN_FOR_EXACT_TOKENS_OUT.
        if (kind == BaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            (bptAmountIn, amountsOut) = _exitExactBPTInForTokensOut(balances, userData);
        } else {
            _revert(Errors.UNHANDLED_EXIT_KIND);
        }
    }

    function _exitExactBPTInForTokensOut(uint256[] memory balances, bytes memory userData)
        internal
        view
        override
        returns (uint256, uint256[] memory)
    {
        // This exit function is the only one that is not disabled if the contract is paused: it remains unrestricted
        // in an attempt to provide users with a mechanism to retrieve their tokens in case of an emergency.
        // This particular exit function is the only one that remains available because it is the simplest one, and
        // therefore the one with the lowest likelihood of errors.

        uint256 bptAmountIn = userData.exactBptInForTokensOut();
        // Note that there is no minimum amountOut parameter: this is handled by `IVault.exitPool`.

        uint256[] memory amountsOut = GyroPoolMath._calcTokensOutGivenExactBptIn(balances, bptAmountIn, totalSupply());
        return (bptAmountIn, amountsOut);
    }

    // Helpers

    /**
     * @dev Computes and distributes fees between the Balancer and the Gyro treasury
     * The fees are computed and distributed in BPT rather than using the
     * Balancer regular distribution mechanism which would pay these in underlying
     */

    function _distributeFees(uint256 invariantBeforeAction) internal {
        // calculate Protocol fees in BPT
        // lastInvariant is the invariant logged at the end of the last liquidity update
        // protocol fees are calculated on swap fees earned between liquidity updates
        (uint256 gyroFees, uint256 balancerFees, address gyroTreasury, address balTreasury) = _getDueProtocolFeeAmounts(
            _lastInvariant,
            invariantBeforeAction
        );

        // Pay fees in BPT
        _payFeesBpt(gyroFees, balancerFees, gyroTreasury, balTreasury);
    }

    /**
     * @dev this function overrides inherited function to make sure it is never used
     */
    function _getDueProtocolFeeAmounts(
        uint256[] memory, // balances,
        uint256[] memory, // normalizedWeights,
        uint256, // previousInvariant,
        uint256, // currentInvariant,
        uint256 // protocolSwapFeePercentage
    ) internal pure override returns (uint256[] memory) {
        revert("Not implemented");
    }

    /**
     * @dev Calculates protocol fee amounts in BPT terms.
     * protocolSwapFeePercentage is not used here b/c we take parameters from GyroConfig instead.
     * Returns: BPT due to Gyro, BPT due to Balancer, receiving address for Gyro fees, receiving address for Balancer
     * fees.
     */
    function _getDueProtocolFeeAmounts(uint256 previousInvariant, uint256 currentInvariant)
        internal
        view
        returns (
            uint256,
            uint256,
            address,
            address
        )
    {
        (uint256 protocolSwapFeePerc, uint256 protocolFeeGyroPortion, address gyroTreasury, address balTreasury) = _getFeesMetadata();

        // Early return if the protocol swap fee percentage is zero, saving gas.
        if (protocolSwapFeePerc == 0) {
            return (0, 0, gyroTreasury, balTreasury);
        }

        // Calculate fees in BPT
        (uint256 gyroFees, uint256 balancerFees) = GyroPoolMath._calcProtocolFees(
            previousInvariant,
            currentInvariant,
            totalSupply(),
            protocolSwapFeePerc,
            protocolFeeGyroPortion
        );

        return (gyroFees, balancerFees, gyroTreasury, balTreasury);
    }

    function _payFeesBpt(
        uint256 gyroFees,
        uint256 balancerFees,
        address gyroTreasury,
        address balTreasury
    ) internal {
        // Pay fees in BPT to gyro treasury
        if (gyroFees > 0) {
            _mintPoolTokens(gyroTreasury, gyroFees);
        }
        // Pay fees in BPT to bal treasury
        if (balancerFees > 0) {
            _mintPoolTokens(balTreasury, balancerFees);
        }
    }

    function _getFeesMetadata()
        internal
        view
        returns (
            uint256,
            uint256,
            address,
            address
        )
    {
        return (
            gyroConfig.getSwapFeePercForPool(address(this), POOL_TYPE),
            gyroConfig.getProtocolFeeGyroPortionForPool(address(this), POOL_TYPE),
            gyroConfig.getAddress(GyroConfigKeys.GYRO_TREASURY_KEY),
            gyroConfig.getAddress(GyroConfigKeys.BAL_TREASURY_KEY)
        );
    }

    /** @notice Effective BPT supply.
     *
     *  This is the same as `totalSupply()` but also accounts for the fact that the pool owes
     *  protocol fees to the pool in the form of unminted LP shares created on the next join/exit,
     *  diluting LPers. Thus, this is the totalSupply() that the next join/exit operation will see.
     *
     *  Equivalent to the respective function in, e.g., WeightedPool, see:
     *  https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedPool.sol#L325-L344
     */
    function getActualSupply() external view returns (uint256) {
        uint256 supply = totalSupply();
        (uint256 gyroFees, uint256 balancerFees, , ) = _getDueProtocolFeeAmounts(_lastInvariant, getInvariant());
        return supply.add(gyroFees).add(balancerFees);
    }

    /// @notice Equivalent to but more efficient than `getInvariant().divDown(getActualSupply())`.
    function getInvariantDivActualSupply() external view returns (uint256) {
        uint256 invariant = getInvariant();
        uint256 supply = totalSupply();
        (uint256 gyroFees, uint256 balancerFees, , ) = _getDueProtocolFeeAmounts(_lastInvariant, invariant);
        uint256 actualSupply = supply.add(gyroFees).add(balancerFees);
        return invariant.divDown(actualSupply);
    }

    function _setPausedState(bool paused) internal override {
        _setPaused(paused);
    }

    // Rate scaling
    // Same as for ECLP
    // SOMEDAY ECLP's code and this code could be moved to ExtensibleWeightedPool2Tokens.

    function _scalingFactor(bool token0) internal view override returns (uint256) {
        IRateProvider rateProvider;
        uint256 scalingFactor;
        if (token0) {
            rateProvider = rateProvider0;
            scalingFactor = _scalingFactor0;
        } else {
            rateProvider = rateProvider1;
            scalingFactor = _scalingFactor1;
        }
        if (address(rateProvider) != address(0)) scalingFactor = scalingFactor.mulDown(rateProvider.getRate());
        return scalingFactor;
    }

    function _adjustPrice(uint256 spotPrice) internal view override returns (uint256) {
        if (address(rateProvider0) != address(0)) spotPrice = spotPrice.mulDown(rateProvider0.getRate());
        if (address(rateProvider1) != address(0)) spotPrice = spotPrice.divDown(rateProvider1.getRate());
        return spotPrice;
    }

    /// @notice Convenience function to fetch the two rates used for scaling the two tokens, as of rateProvider{0,1}.
    /// Note that these rates do *not* contain scaling to account for differences in the number of decimals. The rates
    /// themselves are always 18-decimals.
    function getTokenRates() public view returns (uint256 rate0, uint256 rate1) {
        rate0 = address(rateProvider0) != address(0) ? rateProvider0.getRate() : GyroFixedPoint.ONE;
        rate1 = address(rateProvider1) != address(0) ? rateProvider1.getRate() : GyroFixedPoint.ONE;
    }
}

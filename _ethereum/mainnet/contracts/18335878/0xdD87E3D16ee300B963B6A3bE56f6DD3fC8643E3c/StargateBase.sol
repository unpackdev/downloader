// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./IStargateBaseV1.sol";
import "./Interfaces.sol";

import "./DefinitiveAssets.sol";
import "./DefinitiveErrors.sol";
import "./LPStakingStrategy.sol";

struct StargateConfig {
    uint256 depositTokenPoolId;
    bool stgOnlyEmission;
    address ethRouter;
}

abstract contract StargateBase is IStargateBaseV1, LPStakingStrategy {
    using DefinitiveAssets for IERC20;

    StargateConfig public cfg;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LPStakingConfig memory lpConfig,
        StargateConfig memory strategyConfig
    ) LPStakingStrategy(coreAccessControlConfig, coreSwapConfig, coreFeesConfig, lpConfig) {
        cfg = strategyConfig;
    }

    function _removeLiquidityOneCoin(
        uint256 lpTokenAmount,
        uint256, // unused param `minAmount`
        uint8 // unused param `index`
    ) internal override {
        DefinitiveAssets.validateBalance(LP_TOKEN, lpTokenAmount);
        uint256 deltaCredit = IStargateLPToken(LP_TOKEN).deltaCredit();
        if (lpTokenAmount > deltaCredit) {
            revert ExceededMaxDelta();
        }
        //slither-disable-next-line unused-return
        // NOTE: 'index' is ignored and cfg.depositTokenPoolId is used instead to provide _srcPool
        IStargateRouter(LP_DEPOSIT_POOL).instantRedeemLocal(
            uint16(cfg.depositTokenPoolId),
            lpTokenAmount,
            address(this)
        );
    }

    function _removeLiquidity(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal override {
        return _removeLiquidityOneCoin(lpTokenAmount, minAmounts[0], uint8(cfg.depositTokenPoolId));
    }

    function redeemLocal(
        StargateRedeemPayload memory payload
    ) external payable nonReentrant onlyWhitelisted returns (bool) {
        DefinitiveAssets.validateBalance(LP_TOKEN, payload._amountLP);
        _validateRedeemAddress(address(uint160(bytes20(payload._to))));
        IStargateRouter(LP_DEPOSIT_POOL).redeemLocal{ value: msg.value }(
            payload._dstChainId,
            payload._srcPoolId,
            payload._dstPoolId,
            payload._refundAddress,
            payload._amountLP,
            payload._to,
            payload._lzTxParams
        );
        emit RedeemLocal(payload._dstChainId, payload._srcPoolId, payload._amountLP);
        return true;
    }

    function redeemRemote(
        StargateRedeemPayload memory payload
    ) external payable nonReentrant onlyWhitelisted returns (bool) {
        _validateRedeemAddress(address(uint160(bytes20(payload._to))));
        IStargateRouter(LP_DEPOSIT_POOL).redeemRemote{ value: msg.value }(
            payload._dstChainId,
            payload._srcPoolId,
            payload._dstPoolId,
            payload._refundAddress,
            payload._amountLP,
            payload._minAmountLD,
            payload._to,
            payload._lzTxParams
        );
        emit RedeemRemote(payload._dstChainId, payload._srcPoolId, payload._amountLP);
        return true;
    }

    function _validateRedeemAddress(address _to) internal view {
        if (!hasRole(ROLE_CLIENT, _to) && address(this) != _to) {
            revert InvalidRedemptionRecipient();
        }
    }

    function _stake(uint256 amount) internal override {
        address mLP_TOKEN = LP_TOKEN;
        address mLP_STAKING = LP_STAKING;
        DefinitiveAssets.validateBalance(mLP_TOKEN, amount);
        IERC20(mLP_TOKEN).resetAndSafeIncreaseAllowance(address(this), mLP_STAKING, amount);
        ILPStaking(mLP_STAKING).deposit(LP_STAKING_POOL_ID, amount);
    }

    function _unstake(uint256 amount) internal override {
        if (_getAmountStaked() < amount) {
            revert InputGreaterThanStaked();
        }
        ILPStaking(LP_STAKING).withdraw(LP_STAKING_POOL_ID, amount);
    }

    function _claimAllRewards()
        internal
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {
        (rewardTokens, earnedAmounts) = unclaimedRewards();
        ILPStaking(LP_STAKING).deposit(LP_STAKING_POOL_ID, 0);
    }

    function _getAmountStaked() internal view override returns (uint256 amount) {
        uint256 staked = ILPStaking(LP_STAKING).userInfo(LP_STAKING_POOL_ID, address(this)).amount;
        return staked;
    }

    function _enter(uint256[] calldata amounts, uint256 minAmount) internal override returns (uint256 stakedAmount) {
        _addLiquidity(amounts, minAmount);
        stakedAmount = getBalance(LP_TOKEN);
        _stake(stakedAmount);
    }

    /**
     * @notice Exit Implementation - Unstake LP tokens, and remove liquidity to one asset
     * @dev Protocol does claims when unstaking
     */
    function _exit(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal override {
        _unstake(lpTokenAmount);
        _removeLiquidity(lpTokenAmount, minAmounts);
    }

    /**
     * @notice ExitOne Implementation - Unstake LP tokens, and remove liquidity to one asset
     * @dev Protocol does claims when unstaking
     */
    function _exitOne(uint256 lpTokenAmount, uint256 minAmount, uint8) internal override {
        _unstake(lpTokenAmount);
        _removeLiquidityOneCoin(lpTokenAmount, minAmount, uint8(cfg.depositTokenPoolId));
    }

    function unclaimedRewards()
        public
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {
        address mLP_STAKING = LP_STAKING;
        uint256 mLP_STAKING_POOL_ID = LP_STAKING_POOL_ID;
        rewardTokens = new IERC20[](1);
        earnedAmounts = new uint256[](1);

        if (cfg.stgOnlyEmission) {
            rewardTokens[0] = ILPStakingSTG(mLP_STAKING).stargate();
            earnedAmounts[0] = ILPStakingSTG(mLP_STAKING).pendingStargate(mLP_STAKING_POOL_ID, address(this));
        } else {
            rewardTokens[0] = ILPStakingEmissionToken(mLP_STAKING).eToken();
            earnedAmounts[0] = ILPStakingEmissionToken(mLP_STAKING).pendingEmissionToken(
                mLP_STAKING_POOL_ID,
                address(this)
            );
        }
    }
}

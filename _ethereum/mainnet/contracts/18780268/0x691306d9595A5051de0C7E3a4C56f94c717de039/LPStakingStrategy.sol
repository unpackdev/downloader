// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseRewards.sol";
import "./BaseSwap.sol";
import "./BaseAccessControl.sol";
import "./BaseFees.sol";
import "./CoreMulticall.sol";
import "./BasePermissionedExecution.sol";
import "./BaseSafeHarborMode.sol";
import "./DefinitiveAssets.sol";
import "./DefinitiveErrors.sol";
import "./ILPStakingStrategyV1.sol";

struct LPStakingConfig {
    address[] lpUnderlyingTokens;
    address lpDepositPool;
    address lpStaking;
    address lpToken;
    uint256 stakingPoolId;
}

abstract contract LPStakingStrategy is
    ILPStakingStrategyV1,
    BaseSwap,
    BaseRewards,
    CoreMulticall,
    BasePermissionedExecution,
    BaseSafeHarborMode
{
    using DefinitiveAssets for IERC20;

    address[] public LP_UNDERLYING_TOKENS;
    uint256 public immutable LP_UNDERLYING_TOKENS_COUNT;
    address public immutable LP_DEPOSIT_POOL;
    address public immutable LP_STAKING;
    address public immutable LP_TOKEN;
    uint256 internal immutable LP_STAKING_POOL_ID;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LPStakingConfig memory lpStakingConfig
    ) BaseAccessControl(coreAccessControlConfig) BaseSwap(coreSwapConfig) BaseFees(coreFeesConfig) {
        LP_UNDERLYING_TOKENS = lpStakingConfig.lpUnderlyingTokens;
        LP_UNDERLYING_TOKENS_COUNT = lpStakingConfig.lpUnderlyingTokens.length;
        LP_DEPOSIT_POOL = lpStakingConfig.lpDepositPool;
        LP_STAKING = lpStakingConfig.lpStaking;
        LP_TOKEN = lpStakingConfig.lpToken;
        LP_STAKING_POOL_ID = lpStakingConfig.stakingPoolId;
    }

    /**
     * @dev Internal function to add liquidity to liquidity pool
     *
     * @param amounts       amounts of each token to add liquidity
     * @param minAmount     minimum amount of LP tokens to receive back
     */
    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount) internal virtual;

    /**
     * @dev Internal function to remove liquidity from liquidity pool
     *
     * @param lpTokenAmount     total number of tokens to remove from liquidity
     * @param minAmounts[]      minimum amount of each tokens to receive
     */
    function _removeLiquidity(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal virtual;

    /**
     * @dev Internal function to remove liquidity into a single token
     *
     * @param lpTokenAmount     Total amount of LP tokens to burn
     * @param minAmount         Minimum amount of target asset to get back
     */
    function _removeLiquidityOneCoin(uint256 lpTokenAmount, uint256 minAmount, uint8 index) internal virtual;

    /**
     * @dev internal function to stake amount into staking pool
     *
     * @param lpTokenAmount        number of LP tokens to stake
     
     */
    function _stake(uint256 lpTokenAmount) internal virtual;

    /**
     * @dev internal function to partially unstake from rewards pool
     *
     * @param lpTokenAmount        number of LP tokens to unstake
     
     */
    function _unstake(uint256 lpTokenAmount) internal virtual;

    /**
     * @dev internal function to see the amount of stake
     *
     * @return amount       number of tokens staked
     */
    function _getAmountStaked() internal view virtual returns (uint256 amount);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minAmount
    ) external onlyWhitelisted nonReentrant returns (uint256 lpTokenAmount) {
        address mLP_TOKEN = LP_TOKEN;
        DefinitiveAssets.validateAmounts(amounts);

        uint256 lpTokenBalanceBefore = DefinitiveAssets.getBalance(mLP_TOKEN);
        _addLiquidity(amounts, minAmount);
        lpTokenAmount = DefinitiveAssets.getBalance(mLP_TOKEN) - lpTokenBalanceBefore;
        emit AddLiquidity(amounts, lpTokenAmount);
    }

    function removeLiquidity(
        uint256 lpTokenAmount,
        uint256[] calldata minAmounts
    ) external onlyWhitelisted nonReentrant returns (uint256[] memory amounts) {
        DefinitiveAssets.validateAmount(lpTokenAmount);
        uint256[] memory balancesBefore = _getUnderlyingTokensBalance(new uint256[](LP_UNDERLYING_TOKENS_COUNT));
        _removeLiquidity(lpTokenAmount, minAmounts);

        amounts = _getUnderlyingTokensBalance(balancesBefore);
        emit RemoveLiquidity(lpTokenAmount, amounts);
    }

    function removeLiquidityOneCoin(
        uint256 lpTokenAmount,
        uint256 minAmount,
        uint8 index
    ) external onlyWhitelisted nonReentrant returns (uint256[] memory amounts) {
        DefinitiveAssets.validateAmount(lpTokenAmount);
        uint256[] memory balancesBefore = _getUnderlyingTokensBalance(new uint256[](LP_UNDERLYING_TOKENS_COUNT));
        _removeLiquidityOneCoin(lpTokenAmount, minAmount, index);

        amounts = _getUnderlyingTokensBalance(balancesBefore);
        emit RemoveLiquidity(lpTokenAmount, amounts);
    }

    function stake(uint256 amount) external onlyWhitelisted nonReentrant {
        DefinitiveAssets.validateAmount(amount);
        _stake(amount);
        emit Stake(amount);
    }

    function unstake(uint256 amount) external onlyWhitelisted nonReentrant {
        DefinitiveAssets.validateAmount(amount);
        _unstake(amount);
        emit Unstake(amount);
    }

    function getAmountStaked() public view returns (uint256) {
        return _getAmountStaked();
    }

    function enter(
        uint256[] calldata amounts,
        uint256 minAmount
    ) external onlyWhitelisted stopGuarded nonReentrant returns (uint256 stakedAmount) {
        stakedAmount = _enter(amounts, minAmount);
        if (stakedAmount == 0) {
            revert EnterAllFailed();
        }

        emit Enter(amounts, stakedAmount);
    }

    function exitOne(
        uint256 lpTokenAmount,
        uint256 minAmount,
        uint8 index
    ) external onlyWhitelisted stopGuarded nonReentrant returns (uint256 amount) {
        address[] memory mLP_UNDERLYING_TOKENS = LP_UNDERLYING_TOKENS;
        uint256 balanceBefore = DefinitiveAssets.getBalance(mLP_UNDERLYING_TOKENS[index]);
        _exitOne(lpTokenAmount, minAmount, index);

        amount = DefinitiveAssets.getBalance(mLP_UNDERLYING_TOKENS[index]) - balanceBefore;

        emit ExitOne(lpTokenAmount, mLP_UNDERLYING_TOKENS[index], amount);
    }

    function exit(
        uint256 lpTokenAmount,
        uint256[] calldata minAmounts
    ) external onlyWhitelisted stopGuarded nonReentrant returns (uint256[] memory amounts) {
        uint256[] memory balancesBefore = _getUnderlyingTokensBalance(new uint256[](LP_UNDERLYING_TOKENS_COUNT));
        _exit(lpTokenAmount, minAmounts);
        amounts = _getUnderlyingTokensBalance(balancesBefore);

        emit Exit(lpTokenAmount, amounts);
    }

    /**
     * @dev Internal function to add liquidity and stake
     *
     * @param amounts[]         amounts to enter
     * @param minAmount         minimum amount of LP tokens to receive back
     * @return stakedAmount     lpToken amount received
     */
    function _enter(uint256[] calldata amounts, uint256 minAmount) internal virtual returns (uint256 stakedAmount);

    /**
     * @dev Internal function to exit a stake into a single token
     * @dev Implementations should call _claimAllRewards() if the protocol does not automatically claim when unstaking.
     *
     * @param lpTokenAmount amount of LP tokens to unstake and convert
     * @param minAmount     minimum amount of underlying tokens to receive back
     
     */
    function _exitOne(uint256 lpTokenAmount, uint256 minAmount, uint8 index) internal virtual;

    /**
     * @dev Internal function to exit a stake
     * @dev Implementations should call _claimAllRewards() if the protocol does not automatically claim when unstaking.
     *
     * @param lpTokenAmount amount of LP tokens to unstake and convert
     * @param minAmounts    minimum amount of each token to receive back
     
     */
    function _exit(uint256 lpTokenAmount, uint256[] calldata minAmounts) internal virtual;

    function _getUnderlyingTokensBalance(
        uint256[] memory comparativeBalances
    ) internal view returns (uint256[] memory balancesDelta) {
        uint256 mLP_UNDERLYING_TOKENS_COUNT = LP_UNDERLYING_TOKENS_COUNT;
        address[] memory mLP_UNDERLYING_TOKENS = LP_UNDERLYING_TOKENS;
        balancesDelta = new uint256[](mLP_UNDERLYING_TOKENS_COUNT);
        for (uint256 i = 0; i < mLP_UNDERLYING_TOKENS_COUNT; ) {
            balancesDelta[i] = DefinitiveAssets.getBalance(mLP_UNDERLYING_TOKENS[i]) - comparativeBalances[i];
            unchecked {
                ++i;
            }
        }
    }
}

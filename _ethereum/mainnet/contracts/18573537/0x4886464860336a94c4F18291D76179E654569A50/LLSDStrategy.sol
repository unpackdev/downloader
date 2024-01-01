// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ILLSDStrategyV1.sol";
import "./BaseSwap.sol";
import "./CoreMulticall.sol";
import "./BaseAccessControl.sol";
import "./DefinitiveAssets.sol";
import "./DefinitiveErrors.sol";
import "./BaseFees.sol";
import "./BasePermissionedExecution.sol";
import "./BaseSafeHarborMode.sol";
import "./BaseRewards.sol";
import "./BalancerFlashloanBase.sol";

struct LLSDStrategyConfig {
    address stakingToken;
    address stakedToken;
}

abstract contract LLSDStrategy is
    ILLSDStrategyV1,
    BaseSwap,
    CoreMulticall,
    BasePermissionedExecution,
    BaseSafeHarborMode,
    BaseRewards,
    BalancerFlashloanBase
{
    address[] internal DRY_TOKENS;

    constructor(
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        LLSDStrategyConfig memory llsdConfig,
        address flashloanProviderAddress
    )
        BaseAccessControl(coreAccessControlConfig)
        BaseSwap(coreSwapConfig)
        BaseFees(coreFeesConfig)
        BalancerFlashloanBase(flashloanProviderAddress)
    {
        DRY_TOKENS = new address[](2);
        DRY_TOKENS[0] = llsdConfig.stakedToken;
        DRY_TOKENS[1] = llsdConfig.stakingToken;
    }

    function STAKED_TOKEN() public view returns (address) {
        return DRY_TOKENS[0];
    }

    function STAKING_TOKEN() public view returns (address) {
        return DRY_TOKENS[1];
    }

    modifier emitEvent(FlashLoanContextType _type) {
        (uint256 collateralBefore, uint256 debtBefore, int256[] memory dryBalanceDeltas) = (
            getCollateralAmount(),
            getDebtAmount(),
            _getBalanceDeltas(new int256[](2))
        );

        _;

        emitEnterOrExitEvent(collateralBefore, debtBefore, dryBalanceDeltas, _type);
    }

    modifier enforceMaxLTV(uint256 maxLTV) {
        _;

        // Confirm LTV is below maxLTV
        if (getLTV() > maxLTV) {
            revert ExceededMaxLTV();
        }
    }

    function setFlashloanProvider(address newProvider) external override onlyDefinitiveAdmin {
        _setFlashloanProvider(newProvider);
    }

    function emitEnterOrExitEvent(
        uint256 collateralBefore,
        uint256 debtBefore,
        int256[] memory dryBalancesBefore,
        FlashLoanContextType _type
    ) internal {
        (uint256 collateralAfter, uint256 debtAfter, int256[] memory dryBalanceDeltas, uint256 ltv) = (
            getCollateralAmount(),
            getDebtAmount(),
            _getBalanceDeltas(dryBalancesBefore),
            getLTV()
        );

        if (_type == FlashLoanContextType.ENTER) {
            // Upon enter, collateral and debt amounts can not decrease
            emit Enter(
                collateralAfter,
                collateralAfter - collateralBefore,
                debtAfter,
                debtAfter - debtBefore,
                DRY_TOKENS,
                dryBalanceDeltas,
                ltv
            );
        } else if (_type == FlashLoanContextType.EXIT) {
            // Upon exit, collateral and debt amounts can not increase
            emit Exit(
                collateralAfter,
                collateralBefore - collateralAfter,
                debtAfter,
                debtBefore - debtAfter,
                DRY_TOKENS,
                dryBalanceDeltas,
                ltv
            );
        }
    }

    function enterMulticall(
        uint256 borrowAmount,
        SwapPayload calldata swapPayload,
        uint256 maxLTV
    )
        external
        virtual
        onlyWhitelisted
        stopGuarded
        nonReentrant
        enforceMaxLTV(maxLTV)
        emitEvent(FlashLoanContextType.ENTER)
    {
        address mSTAKED_TOKEN = STAKED_TOKEN();
        // Supply dry balances of staked token
        _supply(DefinitiveAssets.getBalance(mSTAKED_TOKEN));

        _borrow(borrowAmount);

        // Swap in to staked asset
        if (swapPayload.amount > 0) {
            SwapPayload[] memory swapPayloads = new SwapPayload[](1);
            swapPayloads[0] = swapPayload;
            _swap(swapPayloads, mSTAKED_TOKEN);
        }
    }

    function exitMulticall(
        uint256 decollateralizeAmount,
        SwapPayload calldata swapPayload,
        bool repayDebt,
        uint256 maxLTV
    ) external onlyWhitelisted stopGuarded nonReentrant enforceMaxLTV(maxLTV) emitEvent(FlashLoanContextType.EXIT) {
        // Decollateralize
        _decollateralize(decollateralizeAmount);

        address mSTAKING_TOKEN = STAKING_TOKEN();
        uint256 swapOutput = DefinitiveAssets.getBalance(mSTAKING_TOKEN);

        // Swap out of staked asset
        if (swapPayload.amount > 0) {
            SwapPayload[] memory swapPayloads = new SwapPayload[](1);
            swapPayloads[0] = swapPayload;
            _swap(swapPayloads, mSTAKING_TOKEN);

            // Store the amount of staking asset received from swap
            swapOutput = DefinitiveAssets.getBalance(mSTAKING_TOKEN) - swapOutput;
        }

        // Repay debt
        if (repayDebt) {
            // Repay the min of the swap output or the debt amount

            uint256 debtAmount = getDebtAmount();
            uint256 repayAmount = swapOutput < debtAmount ? swapOutput : debtAmount;
            _repay(repayAmount);
        }
    }

    function sweepDust() external onlyWhitelisted stopGuarded nonReentrant {
        (uint256 collateralBefore, uint256 debtBefore) = (getCollateralAmount(), getDebtAmount());

        if (collateralBefore > 0 && debtBefore > 0) {
            _repay(DefinitiveAssets.getBalance(STAKING_TOKEN()));
        }

        _supply(DefinitiveAssets.getBalance(STAKED_TOKEN()));

        (uint256 collateralAfter, uint256 debtAfter) = (getCollateralAmount(), getDebtAmount());

        emit SweepDust(
            collateralAfter,
            collateralAfter - collateralBefore,
            debtAfter,
            debtBefore - debtAfter,
            getLTV()
        );
    }

    function getCollateralAmount() public view virtual returns (uint256);

    function getDebtAmount() public view virtual returns (uint256);

    function getLTV() public view virtual returns (uint256);

    /// @dev By default, `unclaimedRewards()` will return 0 tokens + 0 reward amounts
    function unclaimedRewards()
        public
        view
        virtual
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts)
    {}

    function _borrow(uint256 amount) internal virtual;

    function _decollateralize(uint256 amount) internal virtual;

    function _repay(uint256 amount) internal virtual;

    function _supply(uint256 amount) internal virtual;

    /// @dev By default, `_claimAllRewards()` will revert
    function _claimAllRewards() internal virtual override returns (IERC20[] memory, uint256[] memory) {
        revert InvalidRewardsClaim();
    }

    function _getBalanceDeltas(
        int256[] memory previousDryBalances
    ) internal view returns (int256[] memory dryBalanceDeltas) {
        address[] memory mDryAssets = DRY_TOKENS;
        dryBalanceDeltas = new int256[](mDryAssets.length);
        uint256 length = mDryAssets.length;
        uint256 i = 0;
        while (i < length) {
            dryBalanceDeltas[i] = int256(DefinitiveAssets.getBalance(mDryAssets[i])) - previousDryBalances[i];
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICurveBase.sol";
import "./Interfaces.sol";
import "./DefinitiveAssets.sol";

library ConvexHelper {
    using DefinitiveAssets for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    // https://etherscan.io/address/0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B#code
    function unclaimedCVXRewards(uint256 amount) public view returns (uint256) {
        uint256 supply = IConvexToken(CVX).totalSupply();
        uint256 maxSupply = IConvexToken(CVX).maxSupply();
        uint256 cliff = supply / (IConvexToken(CVX).reductionPerCliff());
        uint256 totalCliffs = IConvexToken(CVX).totalCliffs();

        if (cliff >= totalCliffs) {
            return 0;
        }

        uint256 reduction = totalCliffs - cliff;
        amount = (amount * (reduction)) / (totalCliffs);
        uint256 amtTillMax = maxSupply - (supply);
        if (amount > amtTillMax) {
            amount = amtTillMax;
        }
        return amount;
    }

    function unclaimedRewards(
        address convexRewarder
    ) public view returns (IERC20[] memory rewardTokens, uint256[] memory earnedAmounts) {
        rewardTokens = getRewardTokens(convexRewarder);
        uint256 rewardTokensLength = rewardTokens.length;
        earnedAmounts = new uint256[](rewardTokensLength);
        uint256[2] memory staticRewardTokenAmounts = getStaticRewardTokenAmounts(convexRewarder);

        for (uint256 i; i < rewardTokensLength; ) {
            earnedAmounts[i] = (i < staticRewardTokenAmounts.length)
                ? staticRewardTokenAmounts[i]
                : earnedAmounts[i] = IBaseRewardPool(
                IBaseRewardPool(convexRewarder).extraRewards(i - staticRewardTokenAmounts.length)
            ).earned(address(this));
            unchecked {
                ++i;
            }
        }
    }

    function getRewardTokens(address convexRewarder) public view returns (IERC20[] memory rewardTokens) {
        uint256 extraRewardTokensCount = IBaseRewardPool(convexRewarder).extraRewardsLength();
        IERC20[2] memory staticRewardTokens = getStaticRewardTokens(convexRewarder);
        rewardTokens = new IERC20[](staticRewardTokens.length + extraRewardTokensCount);
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; ) {
            rewardTokens[i] = (i < staticRewardTokens.length)
                ? staticRewardTokens[i]
                : IERC20(
                    IBaseRewardPool(IBaseRewardPool(convexRewarder).extraRewards(i - staticRewardTokens.length))
                        .rewardToken()
                );
            unchecked {
                ++i;
            }
        }
    }

    // CVX and base rewards always occupy first 2 indexes
    function getStaticRewardTokens(address convexRewarder) private view returns (IERC20[2] memory staticRewardTokens) {
        staticRewardTokens[0] = IERC20(CVX);
        staticRewardTokens[1] = IBaseRewardPool(convexRewarder).rewardToken();
    }

    // CVX and base rewards always occupy first 2 indexes
    function getStaticRewardTokenAmounts(
        address convexRewarder
    ) private view returns (uint256[2] memory staticRewardTokenAmounts) {
        uint256 crvRewards = IBaseRewardPool(convexRewarder).earned(address(this));
        staticRewardTokenAmounts[0] = unclaimedCVXRewards(crvRewards);
        staticRewardTokenAmounts[1] = crvRewards;
    }

    function addCurveLiquidity(
        address lpToken,
        address lpDepositPool,
        uint256[] calldata amounts,
        uint256 minAmount,
        bool isMetapool,
        uint256 tokensCount
    ) external returns (bool success) {
        if (tokensCount == 2) {
            uint256[2] memory depositAmounts;
            depositAmounts[0] = amounts[0];
            depositAmounts[1] = amounts[1];
            ICurveBase(lpDepositPool).add_liquidity(depositAmounts, minAmount);
        } else if (tokensCount == 3) {
            uint256[3] memory depositAmounts;
            depositAmounts[0] = amounts[0];
            depositAmounts[1] = amounts[1];
            depositAmounts[2] = amounts[2];
            if (isMetapool) {
                ICurveBase(lpDepositPool).add_liquidity(lpToken, depositAmounts, minAmount);
            } else {
                ICurveBase(lpDepositPool).add_liquidity(depositAmounts, minAmount);
            }
        } else if (tokensCount == 4) {
            uint256[4] memory depositAmounts;
            depositAmounts[0] = amounts[0];
            depositAmounts[1] = amounts[1];
            depositAmounts[2] = amounts[2];
            depositAmounts[3] = amounts[3];
            if (isMetapool) {
                ICurveBase(lpDepositPool).add_liquidity(lpToken, depositAmounts, minAmount);
            } else {
                ICurveBase(lpDepositPool).add_liquidity(depositAmounts, minAmount);
            }
        }

        return true;
    }

    function addCurveLiquidityNative(
        address lpDepositPool,
        uint256[] calldata amounts,
        uint256 nativeAssetAmount,
        uint256 minAmount
    ) external returns (bool success) {
        uint256[2] memory depositAmounts;
        depositAmounts[0] = amounts[0];
        depositAmounts[1] = amounts[1];
        //slither-disable-next-line arbitrary-send-eth
        ICurveNative(lpDepositPool).add_liquidity{ value: nativeAssetAmount }(depositAmounts, minAmount);
        return true;
    }

    function removeCurveLiquidity(
        address lpToken,
        address lpDepositPool,
        uint256 lpTokenAmount,
        uint256[] calldata minAmounts,
        bool isMetapool,
        uint256 tokensCount
    ) external returns (bool success) {
        if (tokensCount == 2) {
            uint256[2] memory minWithdrawAmounts;
            minWithdrawAmounts[0] = minAmounts[0];
            minWithdrawAmounts[1] = minAmounts[1];
            if (isMetapool) {
                ICurveBase(lpDepositPool).remove_liquidity(lpToken, lpTokenAmount, minWithdrawAmounts);
            } else {
                ICurveBase(lpDepositPool).remove_liquidity(lpTokenAmount, minWithdrawAmounts);
            }
        } else if (tokensCount == 3) {
            uint256[3] memory minWithdrawAmounts;
            minWithdrawAmounts[0] = minAmounts[0];
            minWithdrawAmounts[1] = minAmounts[1];
            minWithdrawAmounts[2] = minAmounts[2];
            if (isMetapool) {
                ICurveBase(lpDepositPool).remove_liquidity(lpToken, lpTokenAmount, minWithdrawAmounts);
            } else {
                ICurveBase(lpDepositPool).remove_liquidity(lpTokenAmount, minWithdrawAmounts);
            }
        } else if (tokensCount == 4) {
            uint256[4] memory minWithdrawAmounts;
            minWithdrawAmounts[0] = minAmounts[0];
            minWithdrawAmounts[1] = minAmounts[1];
            minWithdrawAmounts[2] = minAmounts[2];
            minWithdrawAmounts[3] = minAmounts[3];
            if (isMetapool) {
                ICurveBase(lpDepositPool).remove_liquidity(lpToken, lpTokenAmount, minWithdrawAmounts);
            } else {
                ICurveBase(lpDepositPool).remove_liquidity(lpTokenAmount, minWithdrawAmounts);
            }
        }

        return true;
    }
}

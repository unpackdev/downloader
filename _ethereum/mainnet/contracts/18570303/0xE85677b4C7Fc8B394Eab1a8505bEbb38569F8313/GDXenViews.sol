// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GDXen.sol";
import "./GDXenERC20.sol";

/**
 * Helper contract used to optimize gdxen state queries made by clients.
 */
contract GDXenViews {
    /**
     * Main gdxen contract address to get the data from.
     */
    GDXen public gdxen;

    /**
     * Reward token address.
     */
    // GDXenERC20 public dxn;

    /**
     * @param _gdXen GDXen.sol contract address
     */
    constructor(GDXen _gdXen) {
        gdxen = _gdXen;
    }

    // constructor() {
    //     gdxen = GDXen(0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47);
    // }

    /**
     * @return main gdxen contract native coin balance
     */
    function deb0xContractBalance() external view returns (uint256) {
        return address(gdxen).balance;
    }

    /**
     * @dev Withdrawable stake is the amount of gdxen reward tokens that are currently
     * 'unlocked' and can be unstaked by a given account.
     *
     * @param staker the address to query the withdrawable stake for
     * @return the amount in wei
     */
    function getAccWithdrawableStake(
        address staker
    ) external view returns (uint256) {
        uint256 calculatedCycle = gdxen.getCurrentCycle();
        uint256 unlockedStake = 0;

        if (
            gdxen.accFirstStake(staker) != 0 &&
            calculatedCycle > gdxen.accFirstStake(staker)
        ) {
            unlockedStake += gdxen.accStakeCycle(
                staker,
                gdxen.accFirstStake(staker)
            );

            if (
                gdxen.accSecondStake(staker) != 0 &&
                calculatedCycle > gdxen.accSecondStake(staker)
            ) {
                unlockedStake += gdxen.accStakeCycle(
                    staker,
                    gdxen.accSecondStake(staker)
                );
            }
        }

        return gdxen.accWithdrawableStake(staker) + unlockedStake;
    }

    /**
     * @dev Unclaimed fees represent the native coin amount that has been allocated
     * to a given account but was not claimed yet.
     *
     * @param account the address to query the unclaimed fees for
     * @return the amount in wei
     */
    function getUnclaimedFees(address account) external view returns (uint256) {
        uint256 calculatedCycle = gdxen.getCurrentCycle();
        uint256 currentAccruedFees = gdxen.accAccruedFees(account);
        uint256 currentCycleFeesPerStakeSummed;
        uint256 previousStartedCycleTemp = gdxen.previousStartedCycle();
        uint256 lastStartedCycleTemp = gdxen.lastStartedCycle();

        if (calculatedCycle != gdxen.currentStartedCycle()) {
            previousStartedCycleTemp = lastStartedCycleTemp + 1;
            lastStartedCycleTemp = gdxen.currentStartedCycle();
        }

        if (
            calculatedCycle > lastStartedCycleTemp &&
            gdxen.cycleFeesPerStakeSummed(lastStartedCycleTemp + 1) == 0
        ) {
            uint256 feePerStake = 0;
            if (gdxen.summedCycleStakes(lastStartedCycleTemp) != 0) {
                feePerStake =
                    ((gdxen.cycleAccruedFees(lastStartedCycleTemp) +
                        gdxen.pendingFees()) * gdxen.SCALING_FACTOR()) /
                    gdxen.summedCycleStakes(lastStartedCycleTemp);
            }

            currentCycleFeesPerStakeSummed =
                gdxen.cycleFeesPerStakeSummed(previousStartedCycleTemp) +
                feePerStake;
        } else {
            currentCycleFeesPerStakeSummed = gdxen.cycleFeesPerStakeSummed(
                lastStartedCycleTemp + 1
            );
        }

        uint256 currentRewards = getUnclaimedRewards(account) +
            gdxen.accWithdrawableStake(account);

        if (
            calculatedCycle > lastStartedCycleTemp &&
            gdxen.lastFeeUpdateCycle(account) != lastStartedCycleTemp + 1
        ) {
            currentAccruedFees +=
                (
                    (currentRewards *
                        (currentCycleFeesPerStakeSummed -
                            gdxen.cycleFeesPerStakeSummed(
                                gdxen.lastFeeUpdateCycle(account)
                            )))
                ) /
                gdxen.SCALING_FACTOR();
        }

        if (
            gdxen.accFirstStake(account) != 0 &&
            calculatedCycle > gdxen.accFirstStake(account) &&
            lastStartedCycleTemp + 1 > gdxen.accFirstStake(account)
        ) {
            currentAccruedFees +=
                (
                    (gdxen.accStakeCycle(
                        account,
                        gdxen.accFirstStake(account)
                    ) *
                        (currentCycleFeesPerStakeSummed -
                            gdxen.cycleFeesPerStakeSummed(
                                gdxen.accFirstStake(account)
                            )))
                ) /
                gdxen.SCALING_FACTOR();

            if (
                gdxen.accSecondStake(account) != 0 &&
                calculatedCycle > gdxen.accSecondStake(account) &&
                lastStartedCycleTemp + 1 > gdxen.accSecondStake(account)
            ) {
                currentAccruedFees +=
                    (
                        (gdxen.accStakeCycle(
                            account,
                            gdxen.accSecondStake(account)
                        ) *
                            (currentCycleFeesPerStakeSummed -
                                gdxen.cycleFeesPerStakeSummed(
                                    gdxen.accSecondStake(account)
                                )))
                    ) /
                    gdxen.SCALING_FACTOR();
            }
        }

        return currentAccruedFees;
    }

    /**
     * @return the reward token amount allocated for the current cycle
     */
    function calculateCycleReward() public view returns (uint256) {
        return (gdxen.lastCycleReward() * 20000) / 20080;
    }

    /**
     * @dev Unclaimed rewards represent the amount of gdxen reward tokens
     * that were allocated but were not withdrawn by a given account.
     *
     * @param account the address to query the unclaimed rewards for
     * @return the amount in wei
     */
    function getUnclaimedRewards(
        address account
    ) public view returns (uint256) {
        uint256 currentRewards = gdxen.accRewards(account) -
            gdxen.accWithdrawableStake(account);
        uint256 calculatedCycle = gdxen.getCurrentCycle();

        if (
            calculatedCycle > gdxen.lastActiveCycle(account) &&
            gdxen.accCycleBatchesBurned(account) != 0
        ) {
            uint256 lastCycleAccReward = (gdxen.accCycleBatchesBurned(account) *
                gdxen.rewardPerCycle(gdxen.lastActiveCycle(account))) /
                gdxen.cycleTotalBatchesBurned(gdxen.lastActiveCycle(account));

            currentRewards += lastCycleAccReward;
        }

        return currentRewards;
    }

    // 计算地址健康度
    // function getHealth(address account) public view returns (uint256) {
    //     require(gdxen.isOldUser(account), "GDXenViews: not old user");
    //     uint256 health = 0;
    //     // 处理e的辅助计算变量
    //     uint256 SCALING_FACTOR_2 = 1e2;
    //     // 初始健康度
    //     uint256 HEALTH = gdxen.HEALTH_INIT();
    //     // 辅助小数位数计算变量
    //     uint256 SCALING_FACTOR_5 = gdxen.SCALING_FACTOR_5();
    //     // 自然数底数e
    //     uint256 HEALTH_E = gdxen.HEALTH_E();
    //     // 健康度计算辅助变量k
    //     uint256 HEALTH_K = gdxen.HEALTH_K();
    //     // 健康度计算辅助变量a
    //     uint256 HEALTH_A = gdxen.HEALTH_A();
    //     // 地址的第一次烧毁轮次
    //     uint256 accFirstBurnCycle = gdxen.firstBurnCycle(account);
    //     // 现在的轮次
    //     uint256 currentCycle = gdxen.currentCycle();
    //     // 健康度下降计算模型：H_0 * (1/e^(k*x^a))
    //     // 健康度下降计算模型：H_0 * (1/e^(k*x^a))
    //     uint256 HEALTH_X = currentCycle - accFirstBurnCycle;
    //     if (HEALTH_X > 116) {
    //         return health;
    //     }
    //     // k*x^a
    //     uint256 HEALTH_KXA = HEALTH_K * (HEALTH_X ** HEALTH_A);
    //     // k*x^a / 30 得出商
    //     uint256 HEALTH_KXA_30_QUOT = HEALTH_KXA / 30;
    //     // k*x^a % 30 得出余数
    //     uint256 HEALTH_KXA_30_REM = HEALTH_KXA % 30;
    //     if (HEALTH_KXA_30_QUOT > 0) {
    //         health =
    //             HEALTH *
    //             ((1 * SCALING_FACTOR_5 ** (2 + HEALTH_KXA_30_QUOT)) /
    //                 (
    //                     ((((HEALTH_E ** 30 * SCALING_FACTOR_5) /
    //                         SCALING_FACTOR_2 ** 30) ** HEALTH_KXA_30_QUOT) *
    //                         ((HEALTH_E ** HEALTH_KXA_30_REM *
    //                             SCALING_FACTOR_5) /
    //                             SCALING_FACTOR_2 ** HEALTH_KXA_30_REM))
    //                 ));
    //     } else {
    //         health =
    //             HEALTH *
    //             ((1 * SCALING_FACTOR_5 ** 2) /
    //                 (
    //                     ((HEALTH_E ** HEALTH_KXA_30_REM * SCALING_FACTOR_5) /
    //                         SCALING_FACTOR_2 ** HEALTH_KXA_30_REM)
    //                 ));
    //     }
    //     return health;
    // }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./CrossMarginAccounts.sol";
import "./IERC20.sol";

/** 
@title Handles liquidation of accounts below maintenance threshold
@notice Liquidation can be called by the authorized staker, 
as determined in the Admin contract.
If the authorized staker is delinquent, other participants can jump
in and attack, taking their fees and potentially even their stake,
depending how delinquent the responsible authorized staker is.
*/
abstract contract CrossMarginLiquidation is CrossMarginAccounts {
    event LiquidationShortfall(uint256 amount);
    event AccountLiquidated(address account);

    struct Liquidation {
        uint256 buy;
        uint256 sell;
        uint256 blockNum;
    }

    /// record kept around until a stake attacker can claim their reward
    struct AccountLiqRecord {
        uint256 blockNum;
        address loser;
        uint256 amount;
        address stakeAttacker;
    }

    mapping(address => Liquidation) liquidationAmounts;
    address[] internal liquidationTokens;
    address[] internal tradersToLiquidate;

    mapping(address => uint256) public maintenanceFailures;
    mapping(address => AccountLiqRecord) public stakeAttackRecords;
    uint256 public avgLiquidationPerCall = 10;

    uint256 public liqStakeAttackWindow = 5;
    uint256 public MAINTAINER_CUT_PERCENT = 5;

    uint256 public failureThreshold = 10;

    /// Set failure threshold
    function setFailureThreshold(uint256 threshFactor) external onlyOwnerExec {
        failureThreshold = threshFactor;
    }

    /// Set liquidity stake attack window
    function setLiqStakeAttackWindow(uint256 window) external onlyOwnerExec {
        liqStakeAttackWindow = window;
    }

    /// Set maintainer's percent cut
    function setMaintainerCutPercent(uint256 cut) external onlyOwnerExec {
        MAINTAINER_CUT_PERCENT = cut;
    }

    /// @dev calcLiquidationAmounts does a number of tasks in this contract
    /// and some of them are not straightforward.
    /// First of all it aggregates liquidation amounts,
    /// as well as which traders are ripe for liquidation, in storage (not in memory)
    /// owing to the fact that arrays can't be pushed to and hash maps don't
    /// exist in memory.
    /// Then it also returns any stake attack funds if the stake was unsuccessful
    /// (i.e. current caller is authorized). Also see context below.
    function calcLiquidationAmounts(
        address[] memory liquidationCandidates,
        bool isAuthorized
    ) internal returns (uint256 attackReturns) {
        liquidationTokens = new address[](0);
        tradersToLiquidate = new address[](0);

        for (
            uint256 traderIndex = 0;
            liquidationCandidates.length > traderIndex;
            traderIndex++
        ) {
            address traderAddress = liquidationCandidates[traderIndex];
            CrossMarginAccount storage account = marginAccounts[traderAddress];

            if (belowMaintenanceThreshold(account)) {
                tradersToLiquidate.push(traderAddress);
                uint256 len = account.holdingTokens.length;
                for (uint256 sellIdx = 0; len > sellIdx; sellIdx++) {
                    address token = account.holdingTokens[sellIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = account.holdings[token];
                        liquidation.buy = 0;
                        liquidation.blockNum = block.number;
                        liquidationTokens.push(token);
                    } else {
                        liquidation.sell += account.holdings[token];
                    }
                }

                len = account.borrowTokens.length;
                for (uint256 buyIdx = 0; len > buyIdx; buyIdx++) {
                    address token = account.borrowTokens[buyIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    (uint256 loanAmount, ) =
                        Lending(lending()).applyBorrowInterest(
                            account.borrowed[token],
                            token,
                            account.borrowedYieldQuotientsFP[token]
                        );

                    Lending(lending()).payOff(token, loanAmount);

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = 0;
                        liquidation.buy = loanAmount;
                        liquidation.blockNum = block.number;
                        liquidationTokens.push(token);
                    } else {
                        liquidation.buy += loanAmount;
                    }
                }
            }

            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[traderAddress];
            if (isAuthorized) {
                attackReturns += _disburseLiqAttack(liqAttackRecord);
            }
        }
    }

    function _disburseLiqAttack(AccountLiqRecord storage liqAttackRecord)
        internal
        returns (uint256 returnAmount)
    {
        if (liqAttackRecord.amount > 0) {
            // validate attack records, if any
            uint256 blockDiff =
                min(
                    block.number - liqAttackRecord.blockNum,
                    liqStakeAttackWindow
                );

            uint256 attackerCut =
                (liqAttackRecord.amount * blockDiff) / liqStakeAttackWindow;

            Fund(fund()).withdraw(
                PriceAware.peg,
                liqAttackRecord.stakeAttacker,
                attackerCut
            );

            Admin a = Admin(admin());
            uint256 penalty =
                (a.maintenanceStakePerBlock() * attackerCut) /
                    avgLiquidationPerCall;
            a.penalizeMaintenanceStake(
                liqAttackRecord.loser,
                penalty,
                liqAttackRecord.stakeAttacker
            );

            // return remainder, after cut was taken to authorized stakekr
            returnAmount = liqAttackRecord.amount - attackerCut;
        }
    }

    /// Disburse liquidity stake attacks
    function disburseLiqStakeAttacks(address[] memory liquidatedAccounts)
        external
    {
        for (uint256 i = 0; liquidatedAccounts.length > i; i++) {
            address liqAccount = liquidatedAccounts[i];
            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[liqAccount];
            if (
                block.number > liqAttackRecord.blockNum + liqStakeAttackWindow
            ) {
                _disburseLiqAttack(liqAttackRecord);
                delete stakeAttackRecords[liqAccount];
            }
        }
    }

    function liquidateFromPeg() internal returns (uint256 pegAmount) {
        uint256 len = liquidationTokens.length;
        for (uint256 tokenIdx = 0; len > tokenIdx; tokenIdx++) {
            address buyToken = liquidationTokens[tokenIdx];
            Liquidation storage liq = liquidationAmounts[buyToken];
            if (liq.buy > liq.sell) {
                pegAmount += PriceAware.liquidateFromPeg(
                    buyToken,
                    liq.buy - liq.sell
                );
                delete liquidationAmounts[buyToken];
            }
        }
    }

    function liquidateToPeg() internal returns (uint256 pegAmount) {
        uint256 len = liquidationTokens.length;
        for (uint256 tokenIndex = 0; len > tokenIndex; tokenIndex++) {
            address token = liquidationTokens[tokenIndex];
            Liquidation storage liq = liquidationAmounts[token];
            if (liq.sell > liq.buy) {
                uint256 sellAmount = liq.sell - liq.buy;
                pegAmount += PriceAware.liquidateToPeg(token, sellAmount);
                delete liquidationAmounts[token];
            }
        }
    }

    function maintainerIsFailing() internal view returns (bool) {
        (address currentMaintainer, ) =
            Admin(admin()).viewCurrentMaintenanceStaker();
        return
            maintenanceFailures[currentMaintainer] >
            failureThreshold * avgLiquidationPerCall;
    }

    /// called by maintenance stakers to liquidate accounts below liquidation threshold
    function liquidate(address[] memory liquidationCandidates)
        external
        noIntermediary
        returns (uint256 maintainerCut)
    {
        bool isAuthorized = Admin(admin()).isAuthorizedStaker(msg.sender);
        bool canTakeNow = isAuthorized || maintainerIsFailing();

        // calcLiquidationAmounts does a lot of the work here
        // * aggregates both sell and buy side targets to be liquidated
        // * returns attacker cuts to them
        // * aggregates any returned fees from unauthorized (attacking) attempts
        maintainerCut = calcLiquidationAmounts(
            liquidationCandidates,
            isAuthorized
        );

        uint256 sale2pegAmount = liquidateToPeg();
        uint256 peg2targetCost = liquidateFromPeg();
        delete liquidationTokens;

        // this may be a bit imprecise, since individual shortfalls may be obscured
        // by overall returns and the maintainer cut is taken out of the net total,
        // but it gives us the general picture
        uint256 costWithCut =
            (peg2targetCost * (100 + MAINTAINER_CUT_PERCENT)) / 100;
        if (costWithCut > sale2pegAmount) {
            emit LiquidationShortfall(costWithCut - sale2pegAmount);
            canTakeNow =
                canTakeNow &&
                IERC20(peg).balanceOf(fund()) > costWithCut;
        }

        address loser = address(0);
        if (!canTakeNow) {
            // whoever is the current responsible maintenance staker
            // and liable to lose their stake
            loser = Admin(admin()).getUpdatedCurrentStaker();
        }

        // iterate over traders and send back their money
        // as well as giving attackers their due, in case caller isn't authorized
        for (
            uint256 traderIdx = 0;
            tradersToLiquidate.length > traderIdx;
            traderIdx++
        ) {
            address traderAddress = tradersToLiquidate[traderIdx];
            CrossMarginAccount storage account = marginAccounts[traderAddress];

            uint256 holdingsValue = holdingsInPeg(account);
            uint256 borrowValue = loanInPeg(account);

            // 5% of value borrowed
            uint256 maintainerCut4Account =
                (borrowValue * MAINTAINER_CUT_PERCENT) / 100;
            maintainerCut += maintainerCut4Account;

            if (!canTakeNow) {
                // This could theoretically lead to a previous attackers
                // record being overwritten, but only if the trader restarts
                // their account and goes back into the red within the short time window
                // which would be a costly attack requiring collusion without upside
                AccountLiqRecord storage liqAttackRecord =
                    stakeAttackRecords[traderAddress];
                liqAttackRecord.amount = maintainerCut4Account;
                liqAttackRecord.stakeAttacker = msg.sender;
                liqAttackRecord.blockNum = block.number;
                liqAttackRecord.loser = loser;
            }

            // send back trader money

            // include 1% for protocol
            uint256 forfeited =
                maintainerCut4Account + (borrowValue * 101) / 100;
            if (holdingsValue > forfeited) {
                // send remaining funds back to trader
                Fund(fund()).withdraw(
                    PriceAware.peg,
                    traderAddress,
                    holdingsValue - forfeited
                );
            }

            emit AccountLiquidated(traderAddress);
            deleteAccount(account);
        }

        avgLiquidationPerCall =
            (avgLiquidationPerCall * 99 + maintainerCut) /
            100;

        if (canTakeNow) {
            Fund(fund()).withdraw(PriceAware.peg, msg.sender, maintainerCut);
        }

        address currentMaintainer = Admin(admin()).getUpdatedCurrentStaker();
        if (isAuthorized) {
            if (maintenanceFailures[currentMaintainer] > maintainerCut) {
                maintenanceFailures[currentMaintainer] -= maintainerCut;
            } else {
                maintenanceFailures[currentMaintainer] = 0;
            }
        } else {
            maintenanceFailures[currentMaintainer] += maintainerCut;
        }
    }
}

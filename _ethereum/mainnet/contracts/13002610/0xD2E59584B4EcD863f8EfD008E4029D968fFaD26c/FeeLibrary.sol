// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Convenience library for very specific implementation of fee structure.
// Reincorporated to contract due to time constraints.

contract FeeLibrary {

    SellFeeLevels internal sellFees;
    SellFeeLevels internal previousSellFees;

    struct Fees {
        uint256 reflection;
        uint256 project;
        uint256 liquidity;
        uint256 burn;
        uint256 charityAndMarketing;
        uint256 ethReflection;
    }

    function setToZero(Fees storage fees) internal {
        fees.reflection = 0;
        fees.project = 0;
        fees.liquidity = 0;
        fees.burn = 0;
        fees.charityAndMarketing = 0;
        fees.ethReflection = 0;
    }

    function setTo(Fees storage fees, uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee,
            uint256 charityAndMarketingFee, uint256 ethReflectionFee) internal {
        fees.reflection = reflectionFee;
        fees.project = projectFee;
        fees.liquidity = liquidityFee;
        fees.burn = burnFee;
        fees.charityAndMarketing = charityAndMarketingFee;
        fees.ethReflection = ethReflectionFee;
    }

    function setFrom(Fees storage fees, Fees storage newFees) internal {
        fees.reflection = newFees.reflection;
        fees.project = newFees.project;
        fees.liquidity = newFees.liquidity;
        fees.burn = newFees.burn;
        fees.charityAndMarketing = newFees.charityAndMarketing;
        fees.ethReflection = newFees.ethReflection;
    }

    struct SellFees {
        uint256 saleCoolDownTime;
        uint256 saleCoolDownFee;
        uint256 saleSizeLimitPercent;
        uint256 saleSizeLimitPrice;
    }

    struct SellFeeLevels {
        mapping(uint8 => SellFees) level;
    }

    function setToZero(SellFees storage fees) internal {
        fees.saleCoolDownTime = 0;
        fees.saleCoolDownFee = 0;
        fees.saleSizeLimitPercent = 0;
        fees.saleSizeLimitPrice = 0;
    }

    function setTo(SellFees storage fees, uint256 upperTimeLimitInHours, uint256 timeLimitFeePercent, uint256 saleSizePercent, uint256 saleSizeFee) internal {
        fees.saleCoolDownTime = upperTimeLimitInHours;
        fees.saleCoolDownFee = timeLimitFeePercent;
        fees.saleSizeLimitPercent = saleSizePercent;
        fees.saleSizeLimitPrice = saleSizeFee;
    }

    function setTo(SellFees storage fees, SellFees storage newFees) internal {
        fees.saleCoolDownTime = newFees.saleCoolDownTime;
        fees.saleCoolDownFee = newFees.saleCoolDownFee;
        fees.saleSizeLimitPercent = newFees.saleSizeLimitPercent;
        fees.saleSizeLimitPrice = newFees.saleSizeLimitPrice;
    }

    function setToZero(SellFeeLevels storage leveledFees) internal {
        leveledFees.level[1] = SellFees(0, 0, 0, 0);
        leveledFees.level[2] = SellFees(0, 0, 0, 0);
        leveledFees.level[3] = SellFees(0, 0, 0, 0);
        leveledFees.level[4] = SellFees(0, 0, 0, 0);
        leveledFees.level[5] = SellFees(0, 0, 0, 0);
    }

    function setFrom(SellFeeLevels storage leveledFees, SellFeeLevels storage newLeveledFees) internal {
        leveledFees.level[1] = newLeveledFees.level[1];
        leveledFees.level[2] = newLeveledFees.level[2];
        leveledFees.level[3] = newLeveledFees.level[3];
        leveledFees.level[4] = newLeveledFees.level[4];
        leveledFees.level[5] = newLeveledFees.level[5];
    }

    function initSellFees() internal {
        sellFees.level[1] = SellFees({
        saleCoolDownTime: 6 hours,
        saleCoolDownFee: 30,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 30
        });
        sellFees.level[2] = SellFees({
        saleCoolDownTime: 12 hours,
        saleCoolDownFee: 25,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 30
        });
        sellFees.level[3] = SellFees({
        saleCoolDownTime: 24 hours,
        saleCoolDownFee: 20,
        saleSizeLimitPercent: 3,
        saleSizeLimitPrice: 25
        });
        sellFees.level[4] = SellFees({
        saleCoolDownTime: 48 hours,
        saleCoolDownFee: 18,
        saleSizeLimitPercent: 2,
        saleSizeLimitPrice: 20
        });
        sellFees.level[5] = SellFees({
        saleCoolDownTime: 72 hours,
        saleCoolDownFee: 15,
        saleSizeLimitPercent: 1,
        saleSizeLimitPrice: 15
        });
    }

    struct EthBuybacks {
        uint256 liquidity;
        uint256 redistribution;
        uint256 buyback;
    }
}

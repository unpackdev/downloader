//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBMSettings.sol";
import "./CCLib.sol";

contract BMSettings is IBMSettings, Ownable {
    uint256 private baseEfficiency = 5;
    uint256 private efficiencyPerLevel = 1;

    // 100.0 honey per efficiency rank per week;
    // 100e18/(3600*24*7);
    uint256 private gatherFactorBase = 165343915343915;

    uint256 private levelupBase = 13e17; // 1.3
    uint256 private levelupFactor = 100;

    uint256 private cashbackPercent = 20;
    address private cashbackAddress = address(0);

    function getBaseEfficiency() external view override returns (uint256) {
        return baseEfficiency;
    }

    function getEfficiencyPerLevel() external view override returns (uint256) {
        return efficiencyPerLevel;
    }

    function getGatherFactor() external view override returns (uint256) {
        return gatherFactorBase/baseEfficiency;
    }

    function getLevelupPrice(uint256 rank) external view override returns (uint256) {
        return levelupFactor * CCLib.fpowerE18(levelupBase, rank);
    }

    function getCashbackPercent() external view override returns (uint256) {
        return cashbackPercent;
    }

    function getCashbackAddress() external view override returns (address) {
        return cashbackAddress;
    }

    function setBaseEfficiency(uint256 efficiency) external override onlyOwner {
        require(efficiency > 0);
        baseEfficiency = efficiency;
    }

    function setEfficiencyPerLevel(uint256 efficiency) external override onlyOwner {
        require(efficiency > 0);
        efficiencyPerLevel = efficiency;
    }

    function setGatherFactorBase(uint256 base) external override onlyOwner {
        require(base > 0);
        gatherFactorBase = base;
    }

    function setLevelupPriceBaseE18(uint256 base) external override onlyOwner {
        require(base > 0);
        levelupBase = base;
    }

    function setLevelupPriceFactor(uint256 factor) external override onlyOwner {
        require(factor > 0);
        levelupFactor = factor;
    }

    function setCashbackPercent(uint256 percent) external override onlyOwner {
        require(percent <= 100);
        cashbackPercent = percent;
    }

    function setCashbackAddress(address address_) external override onlyOwner {
        cashbackAddress = address_;
    }
}

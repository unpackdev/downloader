//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBMSettings {
    function getBaseEfficiency() external view returns (uint256);
    function getEfficiencyPerLevel() external view returns (uint256);
    function getGatherFactor() external view returns (uint256);
    function getLevelupPrice(uint256 rank) external view returns (uint256);
    function getCashbackPercent() external view returns (uint256);
    function getCashbackAddress() external view returns (address);

    function setBaseEfficiency(uint256 efficiency) external;
    function setEfficiencyPerLevel(uint256 efficiency) external;
    function setGatherFactorBase(uint256 base) external;
    function setLevelupPriceBaseE18(uint256 base) external;
    function setLevelupPriceFactor(uint256 factor) external;
    function setCashbackPercent(uint256 percent) external;
    function setCashbackAddress(address address_) external;
}

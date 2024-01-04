pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT


interface IBasisTreasury {
    function cashPriceCeiling() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
    function getReserve() external view returns (uint256);
    function getBondOraclePrice() external view returns (uint256); 
    function getSeigniorageOraclePrice() external view returns (uint256) ;
    function buyBonds(uint256 amount, uint256 targetPrice) external;
    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}
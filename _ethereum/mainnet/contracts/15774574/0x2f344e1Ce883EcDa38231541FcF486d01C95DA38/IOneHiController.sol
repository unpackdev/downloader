// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOneHiController {
    function createTable(address nftAddr, uint256 targetAmount, bytes32 salt) external;
    function buyTickets(address tableAddr, uint256 amount) external returns(uint256);
    function claimTreasure(address tableAddr, uint256 tokenId) external;
    function luckyClaim(address tableAddr) external;
    //table
    function getFractonSwapAddr() external view returns(address);
    function getVaultAddr() external view returns(address);
    function getSplitProfitRatio() external view returns(uint256);
    function getLuckySplitProfitRatio() external view returns(uint256);
    //frontend
    function getTableAccumulation(address tableAddr) external view returns(uint256);
    function getTableLucky(address tableAddr) external view returns(address);


}

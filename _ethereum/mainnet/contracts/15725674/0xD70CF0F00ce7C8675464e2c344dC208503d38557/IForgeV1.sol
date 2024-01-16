// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IForgeV1 {
    function forgeInfo(uint256 forgeId) external view returns (
        bool isEth,
        address contributionToken,
        uint256 dynasetLp,
        uint256 totalContribution,
        uint256 minContribution,
        uint256 maxContribution,
        uint256 maxCap,
        uint256 contributionPeriod,
        bool withdrawEnabled,
        bool depositEnabled,
        bool forging);
    function userInfo(uint256 forgeId, address contributor) external view 
        returns (uint256 depositAmount, uint256 dynasetsOwed);
    function deposit(uint256 forgeId, uint256 amount, address to) external payable;
}
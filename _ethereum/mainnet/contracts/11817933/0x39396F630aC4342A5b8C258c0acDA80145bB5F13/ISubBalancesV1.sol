// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISubBalancesV1 {
    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external;

    function callOutcomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external;
    
    function getSessionStats(uint256 sessionId) 
        external view returns (address, uint256, uint256, uint256, bool);

    function getSessionEligibility(uint256 sessionId) external view returns (bool[5] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISubBalances {
    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external;

    function callOutcomeStakerTrigger(
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) external;

    function callOutcomeStakerTriggerV1(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) external;

    function createMaxShareSession(
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 newShares,
        uint256 oldShares
    ) external;

    function createMaxShareSessionV1(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 newShares,
        uint256 oldShares
    ) external;
}

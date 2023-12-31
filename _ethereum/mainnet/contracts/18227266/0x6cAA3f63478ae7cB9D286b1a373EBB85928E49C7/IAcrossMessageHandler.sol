// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IAcrossMessageHandler {
    function handleAcrossMessage(
        address tokenSent,
        uint256 amount,
        bool fillCompleted,
        address relayer,
        bytes memory message
    ) external;
}

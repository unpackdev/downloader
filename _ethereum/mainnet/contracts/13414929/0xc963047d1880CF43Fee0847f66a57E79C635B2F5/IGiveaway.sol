// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGiveaway {
    /**
     * Checks if msg.sender is eligible to claim `count` free tokens of `dropId`.
     * Should revert with an error message if not allowed.
     */
    function onClaimFree(
        address sender,
        uint256 dropId,
        uint256 count
    ) external;
}

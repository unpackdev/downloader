// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ITreasury.sol";

interface IRedepositManager {
    // EVENTS

    event Redeposited(
        uint32 indexed productId,
        address asset,
        uint128 amount,
        address receiver,
        bool succeeded
    );

    // FUNCTIONS

    function redeposit(
        ITreasury treasury,
        uint32 productId,
        address asset,
        uint128 amount,
        address receiver
    ) external;
}

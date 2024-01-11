// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IGUniPool {
    function transferOwnership(address newOwner) external;

    function executiveRebalance(
        int24 newLowerTick,
        int24 newUpperTick,
        uint160 swapThresholdPrice,
        uint256 swapAmountBPS,
        bool zeroForOne
    ) external;
}

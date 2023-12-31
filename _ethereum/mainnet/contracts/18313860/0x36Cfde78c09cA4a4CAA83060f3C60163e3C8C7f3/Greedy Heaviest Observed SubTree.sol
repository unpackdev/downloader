/*
    Greedy Heaviest Observed SubTree - GHOST

    Telegram - https://t.me/GreedyHeaviestObservedSubTree
    Website - https://greedyheaviestobservedsubtree.com
    Twitter - https://twitter.com/GHOST_ERC20
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract GHOST is ERC20 {
    constructor() ERC20("Greedy Heaviest Observed SubTree", "GHOST") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}
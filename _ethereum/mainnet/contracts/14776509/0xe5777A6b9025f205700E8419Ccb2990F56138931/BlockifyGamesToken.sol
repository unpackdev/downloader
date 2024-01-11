//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BlockifyGamesToken is ERC20 {
    constructor()
    ERC20(
        "BLOCKIFY | https://blockify.games",
        "BLOCKIFY"
    ) {
        _mint(
            msg.sender,
            1_000_000_000_000 ether
        );
    }
}

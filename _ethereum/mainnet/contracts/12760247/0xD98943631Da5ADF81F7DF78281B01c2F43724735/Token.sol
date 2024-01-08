// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

// t.me/Flokiv2
// This time 100% no tax
// New Dev also working on $STARL

import "./ERC20.sol";

contract Token is ERC20 {

    constructor () public ERC20("Floki Inu V2 t.me/floki_v2", "FLOK2") {
        _mint(msg.sender, 1000000000000 * (10 ** uint256(decimals())));
    }
}
// contracts/DudeCoin.sol
// SPDX-License-Identifier: MIT
// https://dude.army for information
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DudeCoin is ERC20 {
    constructor() ERC20("Dude Coin", "DUDE") {
        _mint(msg.sender, 1337000000 * 10**18);
    }
}
// contracts/WitCoin.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract WitCoin is ERC20{
    constructor() ERC20("Witcoin", "WTC"){
        _mint(msg.sender,21000000*10**18);
    }
}
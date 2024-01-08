// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract QCoin is ERC20 {
    constructor() ERC20("QCoin", "QCN") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}
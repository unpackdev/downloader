// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

//Homer Simpson: D'oh!
//website: https://homercoin.io/

contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol,uint256 initialSupply) ERC20(name, symbol) payable{
        _mint(msg.sender, initialSupply  * 10 ** uint(decimals()));
    }
}

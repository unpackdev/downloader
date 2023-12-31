// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol,uint256 initialSupply) ERC20(name, symbol) payable{
        //创建一个标准的erc20代币合约,包含了名称name  符号symbol 和数量枚initialSupply
        _mint(msg.sender, initialSupply  * 10 ** uint(decimals()));
    }
}

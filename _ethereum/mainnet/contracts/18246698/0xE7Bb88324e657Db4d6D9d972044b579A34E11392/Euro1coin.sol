// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol";

contract Euro1coin is ERC20 {
    constructor() ERC20("Euro1coin", "Eurc"){
        _mint(msg.sender, 1000000000000 * 10 ** 18);
    }
}
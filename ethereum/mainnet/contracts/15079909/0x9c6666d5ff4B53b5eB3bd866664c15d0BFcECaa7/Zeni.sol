// SPDX-License-Identifier: Unlicensed
pragma solidity^0.8.15;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

/** 
*   Token Name: Zeni
*   Symbol: Zeni
*   Total Supply: 10,000,000,000
*   Decimal: 10^18
*/ 

contract Zeni is ERC20, Ownable, ERC20Burnable{

    constructor() ERC20("Zeni", "ZENI"){
        // Total Supply: 10,000,000,000
        // Decimal: 10^18
        _mint(msg.sender, 10 * (10**9) * 10**18);
    }
}
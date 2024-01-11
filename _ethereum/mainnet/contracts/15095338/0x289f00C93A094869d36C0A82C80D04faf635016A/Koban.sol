// SPDX-License-Identifier: Unlicensed
pragma solidity^0.8.15;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

/** 
*   Token Name: Koban
*   Symbol: KOBAN
*   Total Supply: 100,000,000
*   Decimal: 10^18
*/ 

contract Koban is ERC20, Ownable, ERC20Burnable{
    constructor() ERC20("Koban", "KOBAN"){
        _mint(msg.sender, 1 * (10**8) * 10**18);
    }
}
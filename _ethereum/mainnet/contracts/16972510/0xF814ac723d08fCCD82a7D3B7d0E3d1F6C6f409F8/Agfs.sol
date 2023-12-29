// SPDX-License-Identifier: Unlicensed
pragma solidity^0.8.15;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

/** 
*   Token Name: AGF Swap Token
*   Symbol: AGFS
*   Total Supply: 5,000,000,000
*   Decimal: 10^18
*/ 

contract Agfs is ERC20, Ownable, ERC20Burnable{

    constructor() ERC20("AGF Swap Token", "AGFS"){
        // Total Supply: 5,000,000,000
        // Decimal: 10^18
        _mint(msg.sender, 5 * (10**9) * 10**18);
    }
}
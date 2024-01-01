
/*
Don't Buy Pepe 
$DBP
Explore The Future With DBP

Don't Buy Now
No Sell Button

TAX 0%

W: https://dontbuypepe.com/
T: https://t.me/DontBuyPepeOfficialPortal
X: https://twitter.com/DontBuyPepe_
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract DBP is ERC20 { 
    constructor() ERC20("Don't Buy Pepe", "DBP") { 
        _mint(msg.sender, 69_420_000_000 * 10**18);
    }
}
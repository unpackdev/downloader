
/*
HairyPlotterMcCalebGOX

100% Transparency, 100% Drama-free.
No secrets in our spells!  No presale to ensure that every witch, wizard, and muggle gets an equal chance from the start! 
Your profits are YOURS – ZERO taxes, ZERO trickery! 
With the LP contract conjured away, your security is our paramount charm! 

web: https://hairyplottermccalebgox.com
tg : https://t.me/HairyPlotterMcCalebGOX
twt: https://twitter.com/HairyPlotterGOX
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract HairyPlotterMcCalebGOX is ERC20 { 
    constructor() ERC20("HairyPlotterMcCalebGOX", "GOX") { 
        _mint(msg.sender, 15_000_000_000 * 10**18);
    }
}
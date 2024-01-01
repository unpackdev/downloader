/*
           _   _______ ______ _____  
     /\   | | |__   __|  ____|_   _| 
    /  \  | |    | |  | |__    | |   
   / /\ \ | |    | |  |  __|   | |   
  / ____ \| |____| |  | |     _| |_  
 /_/    \_\______|_|  |_|    |_____| 
                                    
Telegram: https://t.me/altfiofficial
Twitter: https://twitter.com/Altfiofficial
Website: https://altfi.org/
Medium: https://altfiofficial.medium.com/
AltFi Whitepaper: altfi.gitbook.io/altfi-whitepaper/
Altfi Wallet: https://wallet.altfi.tech/ 
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract ALTFI is ERC20, Ownable {

    bool private launching;

    constructor() ERC20("AltFi", "AltFi") Ownable(msg.sender) {

        uint256 _totalSupply = 120000 * (10 ** decimals());

        launching = true;

        _mint(msg.sender, _totalSupply);
    }

    function enableTrading() external onlyOwner{
        launching = false;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(launching) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        }

        super._update(from, to, amount);
    }
}
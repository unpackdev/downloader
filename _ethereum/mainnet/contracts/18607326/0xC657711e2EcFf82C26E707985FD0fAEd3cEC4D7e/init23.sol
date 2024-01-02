//Incenti is a decentralized solution uniting projects, creators, and users on Twitter, designed to help you grow, earn, and reward. 
//Powered by AmoLabs
//https://incenti.xyz/
//https://twitter.com/incentixyz
// SPDX-License-Identifier: OSL-3.0
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract AmolabsIncenti is ERC20, Ownable {

    bool private launching;

    constructor() ERC20("Incenti", "INC") Ownable(msg.sender) {

        uint256 _totalSupply = 5000000000000 * (10 ** decimals());

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
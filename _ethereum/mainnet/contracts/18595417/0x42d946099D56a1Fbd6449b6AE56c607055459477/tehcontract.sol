// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";


contract TEHCONTRACT is ERC20, Ownable {
    bool private launching;

    constructor() ERC20("teh coin", "teh coin") Ownable(msg.sender) {
        uint256 _totalSupply = 777777777 * (10 ** decimals());
        launching = true;
        _mint(msg.sender, _totalSupply);
    }
    
    function tehLaunch() external onlyOwner {
        launching = false;
    }
   
    function _update(address from, address to, uint256 amount) internal override {
        if (launching) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        }
        super._update(from, to, amount);
    }

    
   

    
}

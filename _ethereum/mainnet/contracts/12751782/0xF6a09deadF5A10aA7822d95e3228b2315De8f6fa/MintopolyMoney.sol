// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract MintopolyMoney is ERC20, ERC20Capped, ERC20Burnable {

    uint8 private constant DECIMALS = 8;
    
    constructor() ERC20("Mintopoly Money", "MM") ERC20Capped(100000000 * (10 ** DECIMALS)) {
        ERC20._mint(msg.sender, 100000000 * (10 ** DECIMALS));
    }
    
    
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
    
    
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    
    function airdrop(address[] memory _recipients, uint[] memory _values) external returns (bool)  {
        require(_recipients.length == _values.length);
        for (uint i = 0; i < _values.length; i++) {
            require(transfer(_recipients[i], _values[i]));
        }
        return true;
    }

}
/**
    Touch Grass (GRASS)
    Website: https://touchfreshgrass.com/
    Twitter: https://twitter.com/TouchFreshGrass
    Telegram: https://t.me/touchinggrass
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

contract TouchGrass is ERC20, Ownable {
    
    constructor(address _owner) ERC20("Touch Grass", "GRASS") {
        
        uint256 _totalSupply = 1000000000 * 10 ** decimals();

        _mint(_owner, _totalSupply);
        _transferOwnership(_owner);
    }
}

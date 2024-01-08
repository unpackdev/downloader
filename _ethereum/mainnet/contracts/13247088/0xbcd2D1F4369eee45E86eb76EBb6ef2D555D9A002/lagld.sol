// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract Skits is ERC20Capped, Ownable {
    
    constructor(uint256 _hard_cap) ERC20("Skits", "SKITS") ERC20Capped(_hard_cap) {
        
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
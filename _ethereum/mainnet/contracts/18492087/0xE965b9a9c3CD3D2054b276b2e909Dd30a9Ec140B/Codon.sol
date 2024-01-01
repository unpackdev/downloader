// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract Codon is ERC20, ERC20Burnable, ERC20Capped, Ownable {
    constructor()
        ERC20("Codon", "CDN")
        ERC20Capped(200000000 * 10 ** decimals())
        Ownable(msg.sender)
    {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

     function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, value);

        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
        }
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
}

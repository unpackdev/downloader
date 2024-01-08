// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract PresalePetcoin is ERC20, ERC20Burnable, Pausable, Ownable {
    
    uint256 public maxSupply = 10000000000 * 10 ** 9;
    

    constructor() ERC20("Pre-Sale PetCoin", "PREPET") {
        _mint(msg.sender, maxSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    
}
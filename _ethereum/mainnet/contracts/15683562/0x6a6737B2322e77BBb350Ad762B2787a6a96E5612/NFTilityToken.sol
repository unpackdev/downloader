// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// __________                    .___.__               _________         _____   __    
// \______   \_____  __  _  __ __| _/|__|  ____       /   _____/  ____ _/ ____\_/  |_  
//  |    |  _/\__  \ \ \/ \/ // __ | |  |_/ ___\      \_____  \  /  _ \\   __\ \   __\ 
//  |    |   \ / __ \_\     // /_/ | |  |\  \___      /        \(  <_> )|  |    |  |   
//  |______  /(____  / \/\_/ \____ | |__| \___  >    /_______  / \____/ |__|    |__|   
//         \/      \/             \/          \/             \/                        

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

// @custom:security-contact security@bawdicsoft.com
contract NFTilityToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("NFTility Token", "NNT") {
        _mint(msg.sender, 150000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/**
    ___  _   ___    _   ___ ___ ___ ___   _____ ___  _  _____ _  _ 
    | _ \/_\ | _ \  /_\ |   \_ _/ __| __| |_   _/ _ \| |/ / __| \| |
    |  _/ _ \|   / / _ \| |) | |\__ \ _|    | || (_) | ' <| _|| .` |
    |_|/_/ \_\_|_\/_/ \_\___/___|___/___|   |_| \___/|_|\_\___|_|\_|
                                                                    
    PARADISE TOKEN
    Website: https://paradise-token.com/
    Exchange: https://www.paradise.exchange/
**/

contract ParadiseToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("PARADISE TOKEN", "PDT") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
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
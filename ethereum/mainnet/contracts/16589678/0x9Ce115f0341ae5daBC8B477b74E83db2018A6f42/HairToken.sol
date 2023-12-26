// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
                        ▄▄
▀████▀  ▀████▀▀         ██
  ██      ██
  ██      ██   ▄█▀██▄ ▀███ ▀███▄███
  ██████████  ██   ██   ██   ██▀ ▀▀
  ██      ██   ▄█████   ██   ██
  ██      ██  ██   ██   ██   ██
▄████▄  ▄████▄▄████▀██▄████▄████▄

*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HairToken is ERC20, ERC20Burnable, Ownable {
    // Mint initial supply and send it to the
    // initial supply recipient
    constructor(uint256 initialSupply, address initialSupplyRecipient) ERC20("HairDAO Token", "HAIR") {
        _mint(initialSupplyRecipient, initialSupply);
    }

    // Mint new HAIR (can only be called by contract owner)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact patrick.djoko@outlook.fr
    contract SeismToken is ERC20, Ownable {
    constructor() ERC20("SEISMCORP", "SEIS") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

//our first token was SEISMIC, SEIS.
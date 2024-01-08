// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "ERC20.sol";

contract GISToken is ERC20 {
    constructor(uint256 initialSupply, address destinationWallet) ERC20("GISHIS", "GIS") public {
        _mint(destinationWallet, initialSupply);
    }
}
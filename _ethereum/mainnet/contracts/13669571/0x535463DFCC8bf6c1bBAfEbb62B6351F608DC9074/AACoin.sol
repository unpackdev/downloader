// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AACoin is ERC20 {

    
    constructor(uint256 initialSupply) ERC20("Asset Art Coin", "AA") {
        _mint(0x9e50e682b3354F074593f17A791c13EEbA3EA1B8, initialSupply);
    }

}
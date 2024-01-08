// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./ERC20.sol";

/**
 * @title ERC20
 * @dev A super simple ERC20 implementation!
 */
contract SexCoin is ERC20 {

     /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) {
        
        _mint(msg.sender, initialSupply);
    
    }

}
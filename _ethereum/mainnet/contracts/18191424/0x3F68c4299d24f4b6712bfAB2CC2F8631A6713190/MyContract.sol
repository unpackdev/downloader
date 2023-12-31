// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Base.sol";

contract MyContract is ERC20Base {
      constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    )
        ERC20Base(
            _defaultAdmin,
            _name,
            _symbol
        )
    {
		//Pre-Mint the Deployer 200 Tokens
        _mint(msg.sender, 1618033988 * 10 ** decimals()); 
    }
    
    
}

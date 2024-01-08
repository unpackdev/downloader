pragma solidity ^0.6.2;

import "./ERC20Burnable.sol";


contract Token is ERC20Burnable {
    
    
    constructor (string memory _name, string memory _symbol, uint8 _decimals) public ERC20( _name, _symbol) {
        _mint(msg.sender , 100000000000000000000000000); // 100 mil tokens
        _setupDecimals(_decimals);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";
import "./ERC20Detailed.sol";

contract OwnToken is ERC20Mintable, ERC20Detailed {
    
    uint256 public initialAmount = 28420;
    uint8 public constant _decimals = 18;
    string public _name = "OwnFund DAO";
    string public _symbol = "OWN";
    address public minter = 0x6BF71ad81F63c4bd5bf854B7F4C87D3C00c184Fb;
    
    
    constructor () public ERC20Detailed(_name, _symbol, _decimals) {
        _mint(minter, initialAmount * (10 ** uint256(_decimals)));
        addMinter(minter);
    }
}

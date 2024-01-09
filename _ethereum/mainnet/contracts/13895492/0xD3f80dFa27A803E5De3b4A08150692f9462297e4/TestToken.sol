pragma solidity 0.8.6;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract TestToken is ERC20, ERC20Permit {

    constructor(string memory name_, string memory symbol_) 
    public 
    ERC20(name_, symbol_) 
    ERC20Permit(name_) {
        _mint(msg.sender, 10000000000 ether);
    }
}
pragma solidity >=0.6.6;

import "./ExcavoERC20.sol";

contract ERC20 is ExcavoERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
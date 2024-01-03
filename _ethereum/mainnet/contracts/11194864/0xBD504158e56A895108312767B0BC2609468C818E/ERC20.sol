pragma solidity =0.5.16;

import "./MonetTokenERC20.sol";

contract ERC20 is MonetTokenERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}

pragma solidity =0.5.16;

import "./MonetTokenERC20.sol";

contract MonetToken is MonetTokenERC20 {
    
    string public constant name = "Monet";
    string public constant symbol = "MNT";
    uint8 public constant decimals = 18;

    constructor() public {
        _mint(msg.sender,21000e18);
    }
}

pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Unlimited is ERC20 {
    constructor() ERC20("Unlimited", "UNLIPP") {
        mintTokens();
    }

    function mintTokens() public {
        _mint(msg.sender, 100000000000000000000000);
    }
}

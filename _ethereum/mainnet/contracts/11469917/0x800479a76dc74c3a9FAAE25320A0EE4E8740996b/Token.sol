pragma solidity ^0.6.6;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        _mint(msg.sender, 100000 * 10**18);
    }
}

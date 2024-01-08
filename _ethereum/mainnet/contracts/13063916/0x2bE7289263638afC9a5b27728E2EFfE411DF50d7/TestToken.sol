pragma solidity 0.8.6;

import "./ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TEST") {
        _mint(msg.sender, 10000);
    }
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
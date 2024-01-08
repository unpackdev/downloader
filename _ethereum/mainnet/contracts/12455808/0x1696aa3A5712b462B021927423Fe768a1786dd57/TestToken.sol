// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

contract TestToken is ERC20 {
    address public owner;

    constructor() ERC20("TestToken", "TKN") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount, bytes32) public {
        _transfer(msg.sender, owner, amount);
    }
}

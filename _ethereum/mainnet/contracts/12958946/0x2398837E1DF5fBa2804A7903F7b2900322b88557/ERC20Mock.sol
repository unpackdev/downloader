// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ERC20Mock is ERC20 {
	constructor() public ERC20("Mock Token", "MOCK") {}

    function mint(address reciepient, uint256 amount) public {
        _mint(reciepient, amount);
    }
}

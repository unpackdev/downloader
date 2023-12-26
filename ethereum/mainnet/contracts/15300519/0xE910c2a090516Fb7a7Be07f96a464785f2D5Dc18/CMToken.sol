// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract CMToken is ERC20, Ownable {
	constructor() ERC20("CheckMate Token", "CMT") {}

	function mint(uint256 amount, address to) public onlyOwner {
		_mint(to, amount);
	}
}

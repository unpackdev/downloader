// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MatmoToken is ERC20, ERC20Burnable, Ownable {
	constructor() ERC20("Matmo", "MAMO") {
		uint256 _totalSupply = 410000000000;
		_mint(_msgSender(), _totalSupply * 10 ** 18);
	}
}

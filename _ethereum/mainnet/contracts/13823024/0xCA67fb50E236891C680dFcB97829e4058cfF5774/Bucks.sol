// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract AtopiaBucks is ERC20Burnable, Ownable {
	constructor() ERC20("Atopia Bucks", "ABUCKS") {}

	function mint(address account, uint256 amount) external onlyOwner {
		_mint(account, amount);
	}

	function decimals() public view virtual override returns (uint8) {
		return 6;
	}
}

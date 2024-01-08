// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract WrappedToken is IERC20, ERC20Burnable, Ownable {
	constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

	function mint(address account, uint256 amount) external onlyOwner {
		_mint(account, amount);
	}
}

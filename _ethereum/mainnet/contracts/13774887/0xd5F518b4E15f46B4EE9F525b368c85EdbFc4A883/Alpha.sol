// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./Context.sol";

contract Alpha is Context, Ownable, ERC20Burnable, ERC20Pausable {
	constructor(
		string memory name,
		string memory symbol,
		uint256 initialSupply
	) ERC20(name, symbol) {
		_mint(_msgSender(), initialSupply * 10**uint256(decimals()) );
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20, ERC20Pausable) {
		super._beforeTokenTransfer(from, to, amount);
	}
}

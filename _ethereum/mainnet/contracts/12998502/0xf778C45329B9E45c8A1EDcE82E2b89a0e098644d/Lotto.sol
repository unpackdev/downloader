// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract Lotto is Context, ERC20Burnable, Ownable {
	constructor() ERC20("Lottery Coin", "LOTTO") {
		_mint(msg.sender, 1000 * 1000000 * 10**18); //1000 millions
	}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}

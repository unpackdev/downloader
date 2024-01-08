// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

contract TexUsToken is ERC20Permit, ERC20Burnable, Ownable {
	constructor() ERC20Permit("TexUs") ERC20("TexUs Coin", "TEXUS") {
		//Initial Minting
		//Number of Acres x 43560 square ft per acre
		//346 x 43560 = 15,071,760
		_mint(msg.sender, 15071760 * (10**uint256(18)));
	}

	//the mint
	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	// Withdraw currency accidentally sent to the smart contract
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

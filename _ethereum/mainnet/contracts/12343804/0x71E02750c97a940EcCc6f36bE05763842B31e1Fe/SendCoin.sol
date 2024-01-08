// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

contract SendCoin is ERC20Permit, ERC20Burnable, Ownable {
	constructor() ERC20Permit("SENDCOIN") ERC20("SENDCOIN", "NELK") {
		_mint(msg.sender, 10000000 * (10**uint256(18)));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./TinyOwnable.sol";

contract Withdraw is Ownable {

    function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, "No balance");
		payable(msg.sender).transfer(balance);
	}
}
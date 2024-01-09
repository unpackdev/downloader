// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";

contract Whitelist is Ownable {
	mapping(address => bool) whitelist;
	uint256 public TOTAL_MEMBERS = 1000;
	uint256 public members = 0;
	uint256 public WHITELIST_PRICE = 0.017 ether;

	event AddedToWhitelist(address indexed account);
	event RemovedFromWhitelist(address indexed account);
	event WithDraw(address indexed account);

	modifier onlyWhitelisted() {
		require(isWhitelisted(msg.sender));
		_;
	}

	function add(address _address) external payable {
		require(whitelist[_address] == false, "Already on a list");
		require(WHITELIST_PRICE == msg.value, "Wrong mooney amount");
		require(members  < TOTAL_MEMBERS);
		whitelist[_address] = true;
		members++;
		emit AddedToWhitelist(_address);
	}

	function _add(address _address) external onlyOwner {
		require(whitelist[_address] == false, "Already on a list");
		require(members < TOTAL_MEMBERS);
		whitelist[_address] = true;
		members++;
		emit AddedToWhitelist(_address);
	}

	function remove(address _address) external onlyOwner {
		whitelist[_address] = false;
		emit RemovedFromWhitelist(_address);
	}

	function isWhitelisted(address _address) public view returns(bool) {
		return whitelist[_address];
	}

	function withdraw() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function getMembersCount() external view returns(uint256) {
		return members;
	}

	receive() external payable {}

	fallback() external payable {}
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract RoyaltyDistributor {

	address public royalty = 0x2975214b5046354d54e8A1D7Fda712dc98Fa4fa9;
	address public artOne = 0x40261822EbB529d511924F9777476eC47C804870;
	address public artTwo = 0xE01c8cA718B4498c754EC389368E638765cf39B2;
	address public artThree = 0x378623Cc95F39BC823614F8E150fcbbb2EeE6812;

	receive() external payable {
		_distribute(msg.value);
	}

	function _sendGas(address receiver, uint256 amount) private returns (bool success) {
		(success,) = receiver.call{value: amount}("");
	}

	function distribute() external {
		_distribute(address(this).balance);
	}

	function _distribute(uint256 total) private {
		uint256 half = total / 2;
		uint256 quarter = total / 4;
		uint256 eighth = quarter / 2;
		_sendGas(royalty, half);
		_sendGas(artOne, quarter);
		_sendGas(artTwo, eighth);
		_sendGas(artThree, eighth);
	}
}
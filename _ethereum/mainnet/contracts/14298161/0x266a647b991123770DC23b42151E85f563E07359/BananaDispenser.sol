pragma solidity ^0.6.12;

import "IERC20.sol";
import "Ownable.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

contract BananaDispenser is Ownable {

	address public constant BANANA = 0x94e496474F1725f1c1824cB5BDb92d7691A4F03a;
	uint256 public constant initial = 2_850_000 ether;
	uint256 public constant start = 1646100000;
	uint256 public constant end = 1835470800;
	uint256 claimed;

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	} 

	function gib() external onlyOwner {
		uint256 time = min(end, block.timestamp);
		uint256 delta = time - start;
		uint256 totalUnlocked = initial * delta / (end - start);
		uint256 toSend = totalUnlocked - claimed;
		
		claimed = totalUnlocked;
		IERC20(BANANA).transfer(owner(), toSend);
	}
}
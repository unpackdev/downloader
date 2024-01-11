// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author Block Block Punch Click (blockblockpunchclick.com)

contract RoyaltySplits {
	address[] internal addresses = [
		0x39fe417823d976AD135CdbDC5881b75A7cEA0c24, // founder
		0x9262890D8f137501AAC2bEe8720D4177F2d1543b, // production
		0xB03dD45C61ABE74b10148F049C2Cca3098Ef50BF // developer
	];

	uint256[] internal splits = [58, 21, 21];
}

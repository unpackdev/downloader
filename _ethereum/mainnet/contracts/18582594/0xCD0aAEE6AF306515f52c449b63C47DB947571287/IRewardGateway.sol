// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

interface IRewardGateway {
	function getRewardsforPeriod(
		uint256 _tokenId,
		uint64 _start,
		uint64 _end
	) external view;
}

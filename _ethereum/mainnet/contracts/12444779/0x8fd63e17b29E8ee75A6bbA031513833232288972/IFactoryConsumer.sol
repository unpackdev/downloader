//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactoryConsumer {
	function mint(
		address creator,
		uint256 factoryId,
		uint256 amount,
		address royaltyRecipient,
		uint256 royaltyValue
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FactoryConsumer {
	uint256 public currentTokenId;
	// mapping of each token factoryId
	mapping(uint256 => uint256) public tokenFactoryId;

	address public proxyRegistryAddress;
}

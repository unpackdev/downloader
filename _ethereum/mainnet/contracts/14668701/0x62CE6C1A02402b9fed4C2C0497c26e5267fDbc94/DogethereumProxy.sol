// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

/**
 * This contract allows us to work around a limitation of
 * the hardhat-etherscan plugin to verify the proxy source code.
 * It is meant to be identical to OpenZeppelin's TransparentUpgradeableProxy.
 */
contract DogethereumProxy is TransparentUpgradeableProxy {
	constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {}
}

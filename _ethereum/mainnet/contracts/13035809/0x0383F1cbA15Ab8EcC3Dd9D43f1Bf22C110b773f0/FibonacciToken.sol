// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FibonacciToken is ERC20("Fibonacci", "FBI") {
	constructor() {
		_mint(0x41b1f1FDCa2987ad39AE1128CE2b8869ccC6Ab89, 24157817 * (10 ** 5));
	}
}
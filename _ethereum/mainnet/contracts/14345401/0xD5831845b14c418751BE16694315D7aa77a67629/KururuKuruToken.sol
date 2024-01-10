// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";

/**
 * @dev KururuKuruToken kurururururu kukururu kururu
 * kukururu kurukuru rurukuku ruru
 * kururukuru.
 */
contract KururuKuruToken is ERC20Capped {
	constructor()
		ERC20("Kururu Kuru", "KURU")
		ERC20Capped(100_000_000 ether) {
		ERC20._mint(msg.sender, 100_000_000 ether);
	}
}

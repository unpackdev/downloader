pragma solidity ^0.5.1;

import "./ERC223Burnable.sol";
import "./ERC223Detailed.sol";

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract Links is ERC223Detailed, ERC223Burnable {

	constructor () public ERC223Detailed("Smart Links", "LINX", 18) {
		uint256 initialAmount = 20000000000 * (10**uint256(18));
		balances[msg.sender] = balances[msg.sender].add(initialAmount);
		_totalSupply = _totalSupply.add(initialAmount);
		bytes memory empty = hex"00000000";
		emit Transfer(address(0), msg.sender, initialAmount, empty);
	}
}

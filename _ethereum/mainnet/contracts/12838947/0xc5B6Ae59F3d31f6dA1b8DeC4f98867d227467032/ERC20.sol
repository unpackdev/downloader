// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./ERC20.sol";
import "./ERC20PresetFixedSupply.sol";

contract CREDZToken is ERC20PresetFixedSupply {
	constructor() ERC20PresetFixedSupply("CREDZ", "CRDZ", 520000000 * (10 ** uint256(decimals())), msg.sender) {}
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract PerseusToken is ERC20PresetFixedSupply {
	constructor(address owner) ERC20PresetFixedSupply("Perseus Token", "PRS", 100_000_000 ether, owner) {
    }
}

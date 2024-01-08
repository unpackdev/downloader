// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Face Color
contract Trait3 is TraitBase {
	constructor(address factory) TraitBase("Face Color", factory) {
		items.push(Item("Brown", "#FFDAB6"));
		items.push(Item("Pink", "#FFD2EA"));
		items.push(Item("Blue", "#C5C5FF"));
		items.push(Item("Sky", "#BBEFFF"));
		items.push(Item("Green", "#B3FFC7"));
		items.push(Item("Yellow", "#FFE98A"));
		items.push(Item("White", "#FFFFFF"));
		itemCount = items.length;
	}
}

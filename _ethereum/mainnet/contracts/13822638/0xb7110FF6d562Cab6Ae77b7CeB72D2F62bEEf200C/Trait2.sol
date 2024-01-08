// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TraitBase.sol";

// Body Color
contract Trait2 is TraitBase {
	constructor(address factory) TraitBase("Body Color", factory) {
		items.push(Item("Brown", "#FDA78B"));
		items.push(Item("Pink", "#F9BBDC"));
		items.push(Item("Blue", "#A4A4F4"));
		items.push(Item("Sky", "#69DCFF"));
		items.push(Item("Green", "#79E8B3"));
		items.push(Item("Yellow", "#F4DA5B"));
		items.push(Item("Black", "#4F4F4F"));
		itemCount = items.length;
	}
}

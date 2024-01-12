// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC1155NSBaseStorage {
	struct Layout {
		mapping(uint256 => mapping(address => uint256)) balances;
		mapping(address => mapping(address => bool)) operatorApprovals;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("co.sportsmetaverse.contracts.storage.ERC1155NSBaseStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		// slither-disable-next-line timestamp
		// solhint-disable-next-line no-inline-assembly
		assembly {
			l.slot := slot
		}
	}
}

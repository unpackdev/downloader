// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC2771RecipientStorage {
	struct Layout {
		/*
		 * Forwarder singleton we accept calls from
		 */
		address trustedForwarder;
	}

	bytes32 internal constant STORAGE_SLOT =
		keccak256("IERC2771Recipient.contracts.storage.ERC2771RecipientStorage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

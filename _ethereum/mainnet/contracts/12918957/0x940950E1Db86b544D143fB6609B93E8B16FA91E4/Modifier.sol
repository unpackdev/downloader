// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./DiamondLib.sol";
import "./EternalLib.sol";
import "./MutationLib.sol";
import "./IFuckYous.sol";

contract Modifier {
	
	modifier onlyOwner {
		DiamondLib.enforceIsContractOwner();
		_;
	}

	modifier onlyFucker(uint tokenId) {
		EternalLib.enforceIsTokenOwner(tokenId);
		_;
	}

	modifier canMutate(uint tokenId) {
    MutationLib.MutationStorage storage s = MutationLib.mutationStorage();
		EternalLib.enforceIsTokenOwner(tokenId);
		require(
			s.mutationStart,
			'OOPS: mutation has not started.'
		);
		require(
			msg.value >= s.mutationPrice,
			'OOPS: send moar ether.'
		);
		_;
	}
}
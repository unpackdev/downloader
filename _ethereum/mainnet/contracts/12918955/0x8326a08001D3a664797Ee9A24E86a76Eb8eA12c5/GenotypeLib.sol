// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./EternalLib.sol";
import "./AssembleLib.sol";
import "./MutationLib.sol";

// import "./console.sol";

library GenotypeLib {

	// takes tokenId, return a list of layer names
	function deriveFenotype(uint tokenId, bytes16 _template) internal view returns (bytes16[] memory) {
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		bytes16 _genotype = s.templates[_template].genotype;
		bytes16 seedhash = s.templates[_template].seedhash;
		
		//
		bytes16[] memory genotypeKeys = s.genotypes[_genotype];

		// string memory acc;
		// acc = AssembleLib.join(acc, '_template');
		// acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(_template));
		// acc = AssembleLib.join(acc, '_genotype');
		// acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(_genotype));
		// acc = AssembleLib.join(acc, 'GENOTYPE_START');
		
		// for (uint i = 0; i < genotype.length; i++) {
		// 	acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(genotype[i]));
		// }

		// acc = AssembleLib.join(acc, 'GENOTYPE_END');
		// console.log('genotype: ', acc);

		//
		return deriveFenotype(tokenId, seedhash, genotypeKeys);
	}

	// pass in seed
	function deriveFenotype(uint tokenId, bytes16 seedhash, bytes16[] memory genotypeKeys) internal view returns (bytes16[] memory) {		
		//
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();

		// step 1: check to see if we have a hash override
		uint hashy;
		if (m.mutationFenotype[tokenId] != 0) {
			hashy = m.mutationFenotype[tokenId];
		} else {
			// step 2: generate a super simple hash
			// (yes, I know this isn't hiding future metadata traits, don't care)
			hashy = uint(keccak256(abi.encodePacked(tokenId, seedhash)));
		}

		// step 3: split this hash into 32 arrays to seed the attributes
		uint8[32] memory seeds = splitHashIntoFenotype(hashy);
		bytes16[] memory fenotype = new bytes16[](genotypeKeys.length);

		// step 4: loop through the traits
		for (uint i; i < genotypeKeys.length; i++) {
			// step 4.a: get the pool of traits
			bytes16 _genotype = genotypeKeys[i];
			bytes16[] storage genotype = s.genotypes[_genotype];
			if (genotype.length != 0) {
				// step 4.b: if it exists, select a trait from the pool, using the seed
				uint genotypeIndex;
				// CHECK FOR PATTERN!
				if (_genotype == bytes16('#s00-pattern')) {
					uint maybeIndex = seeds[i] % 32;
					if (maybeIndex < genotype.length) {
						genotypeIndex = maybeIndex;
					} else {
						genotypeIndex = 0;
					}
				} else {
					genotypeIndex = seeds[i] % genotype.length;
				}
				// step 4.c: add the selected trait to the accumulated layers
				fenotype[i] = genotype[genotypeIndex];
			} else {
				fenotype[i] = '_err';
			}
		}

		// step 5: return the fenotype
		return fenotype;
	}

	function splitHashIntoFenotype(uint _hash) internal pure returns (uint8[32] memory numbers) {
		for (uint i; i < numbers.length; i++) {
			numbers[i] = uint8(_hash >> (i * 8));
		}

		return numbers;
	}

}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./base64.sol";

import "./EternalLib.sol";
import "./GenotypeLib.sol";
import "./MutationLib.sol";



library AssembleLib {
	using Strings for uint256;

	// assembly

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16 _sequence
	)
		internal
		view
		returns (string memory)
	{
		bytes16[] memory fenotype = GenotypeLib.deriveFenotype(tokenId, _template);

		return assembleSequence(tokenId, _template, _sequence, fenotype);
	}

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16 _sequence,
		bytes16[] memory fenotype
	)
		internal
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		bytes16[] memory sequence = s.sequences[_sequence];
		
		return assembleSequence(tokenId, _template, sequence, fenotype);
	}

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16[] memory sequence,
		bytes16[] memory fenotype
	)
		internal
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];

		string memory acc;

		// acc = join(acc, 'FENOTYPE_START');
		
		// for (uint i = 0; i < fenotype.length; i++) {
		// 	acc = join(acc, bytes16ToString(fenotype[i]));
		// }

		// acc = join(acc, 'FENOTYPE_END');
		
		uint fi; // fenotype index
		uint fv; // fenotype value index

		/*
		Reference: (tokens starting with)
			[a-z] → just the trait
			_ → build token variable
			# → trait variable
			@ → color variable
			$ → build order
			~ → build master
			^ → get from master
		*/

		/*
		This long & convoluted loop does these things:
			1. replace '_token_id' with the actual token id
			2. format the trait "name" (ex: "sad") for the JSON attributes array
			3. insert the trait "value" (ex: "<g id="mouth-sad" />) for the SVG
			4. check for any overides 
			5. recursively assembles any nested build orders
			6. joins build orders & encodes into base64
			7. accumulates the build tokens values
		*/

		for (uint i; i < sequence.length; i++) {
			if (sequence[i] == bytes16('_token_id')) {
				// 1. replace '_token_id' with the actual token id
				acc = join(acc, tokenId.toString());
			} else if (sequence[i] == bytes16('_trait_val')) {
				// 2. format the trait "name" (ex: "sad") for the JSON attributes array
				bytes16 _fv = replaceFirstByte(fenotype[fv], '%');
				acc = join(acc, s.variables[_fv]);
				fv++;
			} else if (sequence[i][0] == '#') {
				// 3. insert the trait "value" (ex: "<G id="mouth-sad" />") for the SVG
				acc = join(acc, s.variables[fenotype[fi]]);
				fi++;
			} else if (sequence[i][0] == '$') {
				// 4. recursively assemble any nested build sequences
				acc = join(acc, assembleSequence(tokenId, _template, sequence[i], fenotype));
			} else if (sequence[i][0] == '^') {
				// 5. check for any overides
				MutationLib.MutationStorage storage m = MutationLib.mutationStorage();
				
				if (sequence[i] == bytes16('^name')) {
					if (abi.encodePacked(m.mutationName[tokenId]).length > 0) {
						acc = join(acc, m.mutationName[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.name, fenotype));
					}
				} else if (sequence[i] == bytes16('^text')) {
					if (abi.encodePacked(m.mutationText[tokenId]).length > 0) {
						acc = join(acc, m.mutationText[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.text, fenotype));
					}
				} else if (sequence[i] == bytes16('^desc')) {
					if (abi.encodePacked(m.mutationDesc[tokenId]).length > 0) {
						acc = join(acc, m.mutationDesc[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.desc, fenotype));
					}
				} else if (sequence[i] == bytes16('^graphics')) {
					acc = join(acc, assembleSequence(tokenId, _template, t.graphics, fenotype));
				}
			} else if (sequence[i][0] == '{') {
				// 6. joins build sequences & encodes into base64

				string memory ecc;
				uint numEncode;
				// step 1: figure out how many build tokens are to be encoded
				for (uint j = i + 1; j < sequence.length; j++) {
					if (sequence[j][0] == '}' && sequence[j][1] == sequence[i][1]) {
						break;
					} else {
						numEncode++;
					}
				}
				// step 2: create a new build sequence
				bytes16[] memory encodeSequence = new bytes16[](numEncode);
				// step 3: populate the new build sequence
				uint k;
				for (uint j = i + 1; j < sequence.length; j++) {
					if (k < numEncode) {
						encodeSequence[k] = sequence[j];
						k++;
						i++; // CRITICAL: this increments the MAIN loop to prevent dups
					} else {
						break;
					}
				}
				// step 4: encode & assemblbe the new build sequence
				ecc = assembleSequence(tokenId, _template, encodeSequence, fenotype);
				// step 5: join the encoded string to the accumulated string
				acc = join(acc, encodeBase64(ecc));
			} else {
				// 7. accumulates the build tokens values
				acc = join(acc, s.variables[sequence[i]]);
			}
		}
		return acc;
	}

	// util

	function join(string memory _a, string memory _b) internal pure returns (string memory) {
		return string(abi.encodePacked(bytes(_a), bytes(_b)));
	}

	function encodeBase64(string memory _str) internal pure returns (string memory) {
		return string(abi.encodePacked(Base64.encode(bytes(_str))));
	}

	function bytes16ToString(bytes16 _bytes) internal pure returns (string memory) {
		uint j; // length

		// handle colors
		for (uint i; i < _bytes.length; i++) {
			if (_bytes[i] != 0) {
				j++;
			}
		}
		// create new string, because solidity strings are weird
		bytes memory str = new bytes(j);
		for (uint i; i < j; i++) {
			str[i] = _bytes[i];
		}

		return string(str);
	}

	//
	// function replaceBytesAtIndex(
	// 	bytes32 original,
	// 	uint position,
	// 	bytes3 toInsert
	// ) public pure returns (bytes32) {
	// 	bytes3 maskBytes = 0xffffff;
	// 	bytes32 mask = bytes32(maskBytes) >> ((position*3) * 8);         
		
	// 	return (~mask & original) | (bytes32(toInsert) >> ((position*3) * 8));
	// }

	function replaceFirstByte(
		bytes16 original,
		bytes1 toInsert
	) internal pure returns (bytes16) {
		bytes1 maskBytes = 0xff;
		bytes16 mask = bytes16(maskBytes) >> 0;         
		
		return (~mask & original) | (bytes16(toInsert) >> 0);
	}
}
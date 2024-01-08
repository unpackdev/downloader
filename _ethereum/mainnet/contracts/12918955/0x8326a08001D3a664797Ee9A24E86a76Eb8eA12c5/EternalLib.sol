// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./IFuckYous.sol";

library EternalLib {

	bytes32 constant ETERNAL_STORAGE_POSITION = keccak256('wtf.fuckyous.eternal.storage');

	struct EternalStorage {
		mapping(bytes16 => string) variables;
		mapping(bytes16 => bytes16[]) sequences;
		mapping(bytes16 => bytes16[]) genotypes;
		mapping(bytes16 => Template) templates;
		Seasonal[] seasonals;
		address fuckyous;
	}

	struct Template {
		bytes16 key;
		bytes16 name; // title of the NFT
		bytes16 text; // text around the circle
		bytes16 desc; // description of the NFT (text under image)

		bytes16 seedhash; // seed the randomness
		bytes16 genotype; // which attributes are selected
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
	}

	struct Seasonal {
		bytes16 template;
		uint boundary;
	}

	function eternalStorage() internal pure returns (EternalStorage storage es) {
		bytes32 position = ETERNAL_STORAGE_POSITION;
		assembly {
			es.slot := position
		}
	}

	function addVariable(bytes16 key, string memory val) internal {
		EternalStorage storage s = eternalStorage();
		s.variables[key] = val;
	}

	function addVariables(bytes16[] memory keys, string[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		for (uint i; i < keys.length; i++) {
			s.variables[keys[i]] = vals[i];
		}
	}

	function addSequence(bytes16 key, bytes16[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		s.sequences[key] = vals;
	}

	// TODO: plural version?

	function addGenotype(bytes16 key, bytes16[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		s.genotypes[key] = vals;
	}

	function addTemplate(
		bytes16 _key,
		bytes16 _name,
		bytes16 _text,
		bytes16 _desc,
		bytes16 _seedhash,
		bytes16 _genotype,
		bytes16 _graphics,
		bytes16 _metadata
	) internal {
		EternalStorage storage s = eternalStorage();
		Template memory template = Template({
			key: _key,
			name: _name,
			text: _text,
			desc: _desc,
			seedhash: _seedhash,
			genotype: _genotype,
			graphics: _graphics,
			metadata: _metadata
		});

		s.templates[_key] = template;
	}

	function addSeasonal(bytes16 _template, uint _boundary) internal {
		EternalStorage storage s = eternalStorage();
		Seasonal memory seasonal = Seasonal({
			template: _template,
			boundary: _boundary
		});

		s.seasonals.push(seasonal);
	}

	function setFuckYousAddress(address _address) internal {
		EternalStorage storage s = eternalStorage();
		s.fuckyous = _address;
	}

	function enforceTokenExists(uint tokenId) internal view {
		require(
			IFuckYous(eternalStorage().fuckyous).ownerOf(tokenId) != address(0),
			'OOPS: non-existent token'
		);
	}

	function enforceIsTokenOwner(uint tokenId) internal view {
		require(
			msg.sender == IFuckYous(eternalStorage().fuckyous).ownerOf(tokenId),
			'OOPS: you are not the owner of this token.'
		);
	}
}

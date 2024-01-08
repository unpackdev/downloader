// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./EternalLib.sol";
import "./Modifier.sol";


contract FuckYousPopulate is Modifier {

  function addVariable(bytes16 key, string memory val) external onlyOwner {
		EternalLib.addVariable(key, val);
	}

	function addVariables(bytes16[] memory keys, string[] memory vals) external onlyOwner {
		EternalLib.addVariables(keys, vals);
	}

	function addSequence(bytes16 key, bytes16[] memory vals) external onlyOwner {
		EternalLib.addSequence(key, vals);
	}

	function addGenotype(bytes16 key, bytes16[] memory vals) external onlyOwner {
		EternalLib.addGenotype(key, vals);
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
	) external onlyOwner {
		EternalLib.addTemplate(_key, _name, _text, _desc, _seedhash, _genotype, _graphics, _metadata);
	}

	function addSeasonal(bytes16 _template, uint _boundary) external onlyOwner {
		EternalLib.addSeasonal(_template, _boundary);
	}

}
// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./EternalLib.sol";
import "./AssembleLib.sol";
import "./GenotypeLib.sol";
import "./MutationLib.sol";


contract FuckYousMetadata {

	// figure out what season using the tokenId
	function getSeasonal(uint tokenId) public view returns (EternalLib.Seasonal memory) {
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();

		for (uint i = 0; i < s.seasonals.length; i++) {
			if (tokenId < s.seasonals[i].boundary) {
				return s.seasonals[i];
			}
		}
		return s.seasonals[0];
	}

	// this is the external function FuckYous calls
	function getGraphics(uint tokenId)
		public
		view
		returns (string memory)
	{
		EternalLib.enforceTokenExists(tokenId);

		EternalLib.Seasonal memory seasonal = getSeasonal(tokenId);

		return getGraphics(tokenId, seasonal.template);
	}

	function getGraphics(uint tokenId, bytes16 _template)
		public
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();

		// check for template override
		bytes16 _tm = m.mutationTemplate[tokenId];

		if (_tm != '') {
			return AssembleLib.assembleSequence(tokenId, _tm, s.templates[_tm].graphics);
		}

		return AssembleLib.assembleSequence(tokenId, _template, t.graphics);
	}

	// this is the external function FuckYous calls
	function getMetadata(uint tokenId)
		public
		view
		returns (string memory)
	{
		EternalLib.enforceTokenExists(tokenId);

		EternalLib.Seasonal memory seasonal = getSeasonal(tokenId);

		return getMetadata(tokenId, seasonal.template);
	}

	function getMetadata(uint tokenId, bytes16 _template)
		public
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();
		
		bytes16[] memory fenotype = GenotypeLib.deriveFenotype(tokenId, _template);

		// check for template override
		bytes16 _tm = m.mutationTemplate[tokenId];
		if (_tm != '') {
			return AssembleLib.assembleSequence(tokenId, _tm, s.templates[_tm].metadata, fenotype);
		}
		
		return AssembleLib.assembleSequence(tokenId, _template, t.metadata, fenotype);
	}

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC721Configurable {
	event ConfigurationURI(uint256 indexed tokenId, string configurationURI);

	// map of tokenId => interactiveConfURI.
	mapping(uint256 => string) private _interactiveConfURIs;

	function _setInteractiveConfURI(uint256 tokenId, string memory interactiveConfURI_)
		internal
		virtual
	{
		_interactiveConfURIs[tokenId] = interactiveConfURI_;
		emit ConfigurationURI(tokenId, interactiveConfURI_);
	}

	/**
	 * Configuration uri for tokenId
	 */
	function interactiveConfURI(uint256 tokenId) public view virtual returns (string memory) {
		return _interactiveConfURIs[tokenId];
	}
}

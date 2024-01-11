// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IThisabled1155{
	function addArtwork(string memory _uri, uint256 printCount) public virtual returns (uint256) {}
	function batchAddArtwork(string[] memory uris, uint256[] memory printCounts) public virtual	returns (uint256[] memory) {}
	function mint(address account, uint256 id, uint256 amount) public virtual {}
	function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public virtual {}
	function tokenURI(uint256 tokenId) public view virtual returns (string memory) {}
	function getMaxPrints(uint256 tokenId) public view virtual returns (uint256) {}
	function getAvailablePrints(uint256 tokenId) public view virtual returns (uint256) {}
}

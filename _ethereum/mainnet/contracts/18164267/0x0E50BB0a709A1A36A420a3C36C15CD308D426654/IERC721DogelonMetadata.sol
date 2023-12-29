// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity 0.8.21;

interface IERC721DogelonMetadata {
	
	function setBaseURI(string memory _baseURI) external;
	
	function setBaseContract(address _baseContract) external;
	
	function tokenURI(uint256 hash) external view returns (string memory);

	function deleteMetadataOverride(uint256 hash) external;
			
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";

import "./ERC721.sol";
import "./ERC2981.sol";

import "./WithOperatorFilter.sol";

contract ERC721WithFilter is Ownable, ERC721, ERC2981, WithOperatorFilter {
	/// @notice file containing the base metadata of the collection (name, description, etc...)
	string public contractURI;

	constructor(string memory name_, string memory ticker, string memory initContractURI) ERC721(name_, ticker) {
		contractURI = initContractURI;
	}

	// =============================================================
	//                       	   Getters
	// =============================================================
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
		return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
	}

	// =============================================================
	//                       	   Interactions
	// =============================================================

	/// @inheritdoc ERC721
	/// @dev overrode to add the FilterOperator
	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	/// @inheritdoc ERC721
	/// @dev overrode to add the FilterOperator
	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	/// @inheritdoc ERC721
	/// @dev overrode to add the FilterOperator
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	/// @inheritdoc ERC721
	/// @dev overrode to add the FilterOperator
	function setApprovalForAll(
		address operator,
		bool _approved
	) public override onlyAllowedOperatorForApproval(operator, _approved) {
		super.setApprovalForAll(operator, _approved);
	}

	// =============================================================
	//                       	   Gated Owner
	// =============================================================

	/// @notice allows contract owner to set the royalties
	/// @param newRoyalties the new royalties infos
	function setDefaultRoyalty(RoyaltyInfo calldata newRoyalties) public onlyOwner {
		_setDefaultRoyalty(newRoyalties.receiver, newRoyalties.royaltyFraction);
	}

	/// @notice Allows owner to switch on/off the OperatorFilter
	/// @param newIsEnabled the new state
	function setIsOperatorFilterEnabled(bool newIsEnabled) public onlyOwner {
		isOperatorFilterEnabled = newIsEnabled;
	}
}

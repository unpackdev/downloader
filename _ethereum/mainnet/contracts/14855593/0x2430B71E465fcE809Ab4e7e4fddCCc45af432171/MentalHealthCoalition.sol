// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Supply.sol";
import "./IMetadataProvider.sol";

/// @title MentalHealthCoalition
/// ERC-1155 contract that support The Mental Health Coalition
contract MentalHealthCoalition is ERC1155Supply, AccessControl, ReentrancyGuard {

	/// Defines the Minter/Burner role
	bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

	/// Indicates that a token id is not currently valid
	/// @dev Future IMetaDataProvider's may support new token ids
	/// @param tokenId The token that was found to be invalid
	error InvalidTokenId(uint256 tokenId);

	/// Indicates that an invalid IMetadataProvider was supplied
	/// @dev Most likely indicates that the supplied IERC165 contract does not respond that it supports IMetadataProvider
	error InvalidProvider();

	/// Indicates that an attempt to remove a token's IMetadataProvider is not acceptable
	/// @dev Once a given token id is minted its IMetadataProvider cannot be removed, only replaced
	error InvalidStateRequest();

	/// Contains IMetadataProvider implementations of mintable tokens
	/// @dev Structs that don't exist will have a 0 address, which will indicate an InvalidTokenId
	mapping (uint256 => IMetadataProvider) private _providers;

	/// Constructs the MentalHealthCoalition ERC-1155 contract
	constructor() ERC1155("") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setRoleAdmin(MINTER_BURNER_ROLE, DEFAULT_ADMIN_ROLE);
	}

	/// Mints and burns according to the calling Mint/Burner role
	/// @dev Supports a wide variety of minting policies and allows for future innovation
	/// @param owner The owner of the minted or burned tokens
	/// @param mintTokenIds The token ids that will be minted
	/// @param mintTokenAmounts The amounts of tokens to be minted, mapped 1:1 to `mintTokenIds`
	/// @param burnTokenIds The token ids that will be burned
	/// @param burnTokenAmounts The amounts of tokens to be burned, mapped 1:1 to `burnTokenIds`
	function mintBurnBatch(address owner, uint256[] calldata mintTokenIds, uint256[] calldata mintTokenAmounts, uint256[] calldata burnTokenIds, uint256[] calldata burnTokenAmounts) external nonReentrant onlyRole(MINTER_BURNER_ROLE) {
		if (mintTokenIds.length > 0) {
			_mintBatch(owner, mintTokenIds, mintTokenAmounts, "");
		}
		if (burnTokenIds.length > 0) {
			_burnBatch(owner, burnTokenIds, burnTokenAmounts);
		}
	}

	/// Sets or updates the contract responsible for providing the token's metadata
	/// @dev If no tokens have been minted, it is possible to delete the provider by passing in a 0 address
	/// @param tokenId The token id to modify
	/// @param provider The IMetadataProvider responsible for returning the token's metadata
	function setTokenProvider(uint256 tokenId, address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
		if (provider == address(0)) {
			// Do not delete if there's a minted amount
			if (totalSupply(tokenId) > 0) revert InvalidStateRequest();
			delete _providers[tokenId];
		} else if (!IERC165(provider).supportsInterface(type(IMetadataProvider).interfaceId)) {
			revert InvalidProvider();
		} else {
			_providers[tokenId] = IMetadataProvider(provider);
		}
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
		return super.supportsInterface(interfaceId); // Merges AccessControl and ERC1155 implementations
	}

	/// @inheritdoc IERC1155MetadataURI
	function uri(uint256 tokenId) public view override returns (string memory) {
		IMetadataProvider provider = _providers[tokenId];
		// Checking the address is how we know whether the record exists
		if (address(provider) == address(0)) revert InvalidTokenId(tokenId);
		return provider.metadata(tokenId);
	}

	// Do not allow mints of unconfigured token ids by checking for an IMetadataProvider
	function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
		if (from != address(0)) return; // This override only cares about mints
		for (uint index = 0; index < ids.length;) {
			uint tokenId = ids[index];
			if (address(_providers[tokenId]) == address(0)) revert InvalidTokenId(tokenId);
			unchecked { ++index; } // Gas-efficient and still safe way of incrementing the loop iterator
		}
	}

	/// @dev Override with empty implementation to save contract space
	// solhint-disable-next-line no-empty-blocks
	function _setURI(string memory) internal override pure { }
}

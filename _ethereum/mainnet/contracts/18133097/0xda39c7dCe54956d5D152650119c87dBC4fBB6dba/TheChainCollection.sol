//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC721WithFilter.sol";

import "./IMetadataHelper.sol";
import "./ITheChainCollection.sol";

contract TheChainCollection is ITheChainCollection, ERC721WithFilter {
	error NotAuthorized();
	error InvalidCreator();
	error KnownHash();

	/// @notice the contract (if set) used to compute the metadata link
	address public metadataHelper;

	/// @notice the contract (if set) used to compute the royalties
	address public royaltiesHelper;

	/// @notice the account allowed to mint on current contract
	mapping(address => bool) public minters;

	// THE_CHAIN token hash => tokenData
	mapping(bytes32 => HashData) public hashData;

	// token id to THE_CHAIN token hash
	mapping(uint256 => bytes32) public tokenToHash;

	modifier onlyMinter() {
		if (!minters[msg.sender]) {
			revert NotAuthorized();
		}
		_;
	}

	constructor(
		string memory initContractURI,
		RoyaltyInfo memory initRoyalties
	) ERC721WithFilter("The Chain", "THE_CHAIN", initContractURI) {
		_setDefaultRoyalty(initRoyalties.receiver, initRoyalties.royaltyFraction);

		// by default we enable operator filter, can be disabled later
		isOperatorFilterEnabled = true;

		__WithOperatorFilterInit();
	}

	// =============================================================
	//                       	   Getters
	// =============================================================

	/// @notice returns the hashData linked to a token(/block)
	/// @param tokenId the token id
	function getBlockData(uint256 tokenId) public view returns (bytes32 tokenHash, HashData memory tokenData) {
		tokenHash = tokenToHash[tokenId];
		tokenData = hashData[tokenHash];
	}

	/// @inheritdoc ERC721
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		_requireMinted(tokenId);

		string memory uri;
		address metadataHelper_ = metadataHelper;
		if (metadataHelper_ != address(0)) {
			uri = IMetadataHelper(metadataHelper).tokenURI(address(this), tokenId);
		}

		if (bytes(uri).length == 0) {
			(, HashData memory tokenData) = getBlockData(tokenId);
			uri = tokenData.uri;
		}

		return uri;
	}

	/// @inheritdoc IERC2981
	function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
		address royaltiesHelper_ = royaltiesHelper;
		if (royaltiesHelper_ != address(0)) {
			return IERC2981(royaltiesHelper).royaltyInfo(tokenId, salePrice);
		}

		return super.royaltyInfo(tokenId, salePrice);
	}

	// =============================================================
	//                       	   Gated Minter
	// =============================================================

	function mint(
		uint256 tokenId,
		address creator,
		address transferTo,
		bytes32 currentHash,
		bytes32 previousHash,
		string calldata uri
	) external override onlyMinter {
		if (creator == address(0)) {
			revert InvalidCreator();
		}

		if (hashData[currentHash].creator != address(0)) {
			revert KnownHash();
		}

		hashData[currentHash] = HashData(previousHash, creator, uint96(tokenId), uri);
		tokenToHash[tokenId] = currentHash;

		_mint(creator, tokenId);
		if (transferTo != address(0)) {
			_transfer(creator, transferTo, tokenId);
		}
	}

	// =============================================================
	//                       	   Gated Owner
	// =============================================================

	/// @notice Allows owner to update the uri of an artwork
	/// @param tokenId the token to update
	/// @param newURI the new token uri
	function setBlockURI(uint256 tokenId, string calldata newURI) external onlyOwner {
		_requireMinted(tokenId);

		hashData[tokenToHash[tokenId]].uri = newURI;
	}

	/// @notice Allows owner to update metadataHelper
	/// @param newMetadataHelper the new address of the metadata helper
	function setMetadataHelper(address newMetadataHelper) external onlyOwner {
		metadataHelper = newMetadataHelper;
	}

	/// @notice Allows owner to update royaltiesHelper
	/// @param newRoyaltiesHelper the new address of the royalties helper
	function setRoyaltiesHelper(address newRoyaltiesHelper) external onlyOwner {
		royaltiesHelper = newRoyaltiesHelper;
	}

	/// @notice Allows owner to update the minters
	/// @param accounts the accounts to edit
	/// @param canMint if they can mint or not
	function setMinters(address[] calldata accounts, bool canMint) external onlyOwner {
		for (uint256 i; i < accounts.length; i++) {
			minters[accounts[i]] = canMint;
		}
	}
}

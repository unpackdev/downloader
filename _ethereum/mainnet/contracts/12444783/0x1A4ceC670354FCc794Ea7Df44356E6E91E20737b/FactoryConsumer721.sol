// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./OwnableOperators.sol";
import "./GroupedURI.sol";
import "./ERC721Configurable.sol";
import "./IERCWithRoyalties.sol";
import "./ERC2981Royalties.sol";
import "./IFactoryConsumer.sol";
import "./FactoryConsumer.sol";
import "./ProxyRegistry.sol";

contract FactoryConsumer721 is
	IFactoryConsumer,
	OwnableOperators,
	ERC721Upgradeable,
	GroupedURI,
	ERC721Configurable,
	ERC2981Royalties,
	FactoryConsumer
{
	using StringsUpgradeable for uint256;

	function initialize(
		string memory name_,
		string memory symbol_,
		address factoriesHolder_,
		string memory baseURI_,
		address proxyRegistryAddress_
	) public initializer {
		__OwnableOperators_init();
		__ERC721_init(name_, symbol_);
		__GroupedURI_init(baseURI_);

		// give operator role to factory holder
		_addOperator(factoriesHolder_);

		proxyRegistryAddress = proxyRegistryAddress_;
	}

	/**
	 * @dev Need to override suportsInterface because both AccessControlUpgradeable and ERC721Upgradeable
	 * have a specific supportsInterface
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721Upgradeable, ERC2981Royalties)
		returns (bool)
	{
		return
			// legacy beyond royalties
			interfaceId == type(IERCWithRoyalties).interfaceId ||
			ERC2981Royalties.supportsInterface(interfaceId) ||
			ERC721Upgradeable.supportsInterface(interfaceId);
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

		// get base uri from tokenId's Group
		string memory baseURI = _getIdGroupURI(tokenId);
		return
			bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
	}

	function getTokenFactory(uint256 tokenId) public view returns (uint256) {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

		return tokenFactoryId[tokenId];
	}

	/**
	 * @dev function called by "BeyondFactory" to create a token
	 *
	 * @param creator - token creator
	 * @param factoryId - factory Id
	 */
	function mint(
		address creator,
		uint256 factoryId,
		uint256, // unused param
		address royaltyRecipient,
		uint256 royaltyValue
	) external override onlyOperator returns (uint256) {
		uint256 tokenId = currentTokenId++;

		// add to current group - for URI
		_addIdToCurrentGroup(tokenId);

		// mint
		_safeMint(creator, tokenId, '');

		// save factoryId for token
		// can be used by other contracts for permissions
		tokenFactoryId[tokenId] = factoryId;

		if (royaltyValue > 0) {
			_setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
		}

		return tokenId;
	}

	function burn(uint256 tokenId) public {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		_burn(tokenId);
	}

	/**
	 * @dev Function to increment the group
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function setNextGroup(string memory currentGroupNewURI, string memory nextGroupBaseURI)
		external
		onlyOwner
	{
		_setNnextGroup(currentGroupNewURI, nextGroupBaseURI);
	}

	/**
	 * @dev Function to change group id for specific ids
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function setIdGroupIdBatch(uint256[] memory ids, uint256[] memory groupIds) external onlyOwner {
		_setIdGroupIdBatch(ids, groupIds);
	}

	/**
	 * @dev Function to change groups uris
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function setGroupURIBatch(uint256[] memory groupIds, string[] memory uris) external onlyOwner {
		_setGroupURIBatch(groupIds, uris);
	}

	// configurable interactive nft
	/**
	 * @dev set interactive configuration uri for a token
	 */
	function setInteractiveConfURI(uint256 tokenId, string memory interactiveConfURI_) external {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721Configurable: caller is not owner nor approved'
		);

		_setInteractiveConfURI(tokenId, interactiveConfURI_);
	}

	/**
	 * Configuration uri for tokenId
	 */
	function interactiveConfURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
		return ERC721Configurable.interactiveConfURI(tokenId);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner_, address operator)
		public
		view
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner_)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner_, operator);
	}

	// Legacy Beyond Marketplace Royalties
	/**
	 * @dev returns how much royalties are required for `id`
	 *
	 * @return uint256
	 */
	function getRoyalties(uint256 id) public view returns (uint256) {
		// get royalties from factoryHolder
		return _royalties[id].value;
	}

	/**
	 * @dev this is called by other contracts to send royalties for a given id
	 *
	 * @return "bytes4(keccak256('onRoyaltiesReceived(uint256)'))"
	 */
	function onRoyaltiesReceived(uint256 id) external payable returns (bytes4) {
		// this means that a marketplace send royalties for id
		address recipient = _royalties[id].recipient;

		// do a direct transfer, no claiming here
		payable(recipient).transfer(msg.value);

		return this.onRoyaltiesReceived.selector;
	}
}

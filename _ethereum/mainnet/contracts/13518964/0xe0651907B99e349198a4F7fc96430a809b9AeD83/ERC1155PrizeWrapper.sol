// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

/// @title Token wrapper for making ERC1155 compatible with ERC721 Raffle.
/// @author Valerio Leo @valeriohq

contract ERC1155PrizeWrapper is ERC721, IERC1155Receiver, ERC721Burnable {
	using Counters for Counters.Counter;

  address public raffleAddress;

	Counters.Counter private _tokenIdTracker;


	struct WrappedToken {
		address tokenAddress;
		uint256 tokenId;
	}

	mapping(uint256 => WrappedToken) public wrappedTokens;

	constructor(
    string memory name,
    string memory symbol,
    address _raffleAddress
  ) ERC721(name, symbol) {
		require(_raffleAddress != address(0), "Raffle address cannot be ZERO");

    raffleAddress = _raffleAddress;
  }

	/**
	 * @dev Function to wrap tokens.
	 * @param originalTokenAddress The token address to wrap.
	 * @param originalTokenId The token id to wrap.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function wrapErc1155(address originalTokenAddress, uint256 originalTokenId) public returns (bool) {
		// pull the token
		ERC1155(originalTokenAddress)
			.safeTransferFrom(msg.sender, address(this), originalTokenId, 1, '');

		uint256 tokenId = _tokenIdTracker.current();
		// create a new wrapper token
		super._safeMint(msg.sender, tokenId);
		_tokenIdTracker.increment();

		// link the data
		wrappedTokens[tokenId] = WrappedToken({
			tokenAddress: originalTokenAddress,
			tokenId: originalTokenId
		});

		return true;
	}

	/**
	 * @dev Function to wrap tokens.
	 * @param originalTokenAddresses The token address to wrap.
	 * @param originalTokenIds The token id to wrap.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function batchWrapErc1155(
		address[] memory originalTokenAddresses,
		uint256[] memory originalTokenIds
	)
		public
		returns (bool)
	{
		require(originalTokenAddresses.length == originalTokenIds.length, "Token address and token id arrays must be the same length");

		for (uint256 index = 0; index < originalTokenAddresses.length; index++) {
			wrapErc1155(originalTokenAddresses[index], originalTokenIds[index]);
		}
		return true;
	}

	/**
	 * @dev Function to unwrap tokens. Anyone can call this function. The unwrapped token
	 * will be returned to the current owner of the wrapped token.
	 * @param tokenId The token id to unwrap.
	 */
	function unwrapErc1155(uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(owner == msg.sender, "Only owner can unwrap");

		_unwrapErc1155(tokenId, owner);
	}
	
	function _unwrapErc1155(uint256 tokenId, address receiver) internal {
		WrappedToken memory wrappedToken = wrappedTokens[tokenId];

		ERC1155(wrappedToken.tokenAddress)
			.safeTransferFrom(address(this), receiver, wrappedToken.tokenId, 1, '');

		// we burn the wrapper token and free up storage
		super._burn(tokenId);
		delete wrappedTokens[tokenId];
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public override {
		super.safeTransferFrom(from, to, tokenId);

		// if the raffleAddress is also the sender, we unwrap on behalf of users
		if(from == raffleAddress && msg.sender == raffleAddress) {
			_unwrapErc1155(tokenId, to);
		}
	}

	/**
	*	@dev Handles the receipt of a single ERC1155 token type. This function is
		called at the end of a `safeTransferFrom` after the balance has been updated.
		To accept the transfer, this must return
		`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
		(i.e. 0xf23a6e61, or its own function selector).
	*	@param operator The address which initiated the transfer (i.e. msg.sender)
	*	@param from The address which previously owned the token
	*	@param id The ID of the token being transferred
	*	@param value The amount of tokens being transferred
	*	@param data Additional data with no specified format
	*	@return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
	*/
	function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	/**
	* @dev Handles the receipt of a multiple ERC1155 token types. This function
		is called at the end of a `safeBatchTransferFrom` after the balances have
		been updated. To accept the transfer(s), this must return
		`bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
		(i.e. 0xbc197c81, or its own function selector).
	* @param operator The address which initiated the batch transfer (i.e. msg.sender)
	* @param from The address which previously owned the token
	* @param ids An array containing ids of each token being transferred (order and length must match values array)
	* @param values An array containing amounts of each token being transferred (order and length must match ids array)
	* @param data Additional data with no specified format
	* @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
	*/
	function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

import "./ECDSA.sol";

import "./ERC165.sol";
import "./IERC721.sol";
import "./ERC1155NSBase.sol";
import "./ERC1155NSBaseStorage.sol";

import "./LandTypes.sol";
import "./LandInternal.sol";

import "./LandStorage.sol";

contract LandToken is LandInternal, ERC165 {
	// Overrides

	function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
		return _isApprovedForAll(_owner, operator);
	}

	function versionRecipient() external view virtual override returns (string memory) {
		return "2.2.5";
	}

	// views

	function canClaim(ClaimRequest memory request, bytes calldata signature)
		public
		view
		claimActive
		returns (bool isValid)
	{
		require(_verify(_hashClaim(request), signature), "canClaim: invalid signature");
		require(_msgSender() == request.to, "canClaim: not buyer");
		// slither-disable-next-line timestamp
		// solhint-disable-next-line not-rely-on-time
		require(request.deadline > block.timestamp, "canClaim: signature expired");
		// We check the stock internally
		return true;
	}

	function canMint(MintRequest memory request, bytes calldata signature)
		public
		view
		mintActive
		onlyEOA
		returns (bool isValid)
	{
		require(_verify(_hashMint(request), signature), "canMint: invalid signature");
		require(_msgSender() == request.to, "canMint: not buyer");
		// slither-disable-next-line timestamp
		// solhint-disable-next-line not-rely-on-time
		require(request.deadline > block.timestamp, "canMint: signature expired");
		// We check the stock internally
		return true;
	}

	function canMintMany(MintManyRequest memory request, bytes calldata signature)
		public
		view
		mintActive
		onlyEOA
		returns (bool isValid)
	{
		require(_verify(_hashMintMany(request), signature), "canMintMany: invalid signature");
		require(_msgSender() == request.to, "canMintMany: not buyer");
		// slither-disable-next-line timestamp
		// solhint-disable-next-line not-rely-on-time
		require(request.deadline > block.timestamp, "canMintMany: signature expired");
		require(request.count.length <= LandStorage._getIndex(), "canMintMany: wrong index");
		// We check the stock internally
		return true;
	}

	// Callable

	function claim(ClaimRequest memory request, bytes calldata signature) public {
		require(canClaim(request, signature), "claim: invalid");
		_claimInternal(request.tokenIds);
	}

	// Payable

	/**
	 * Mint in a specific zone for a count
	 */
	function mint(MintRequest memory request, bytes calldata signature) public payable {
		require(canMint(request, signature), "mint: invalid");

		uint256 price = LandStorage._getPrice();
		require(msg.value == price * request.count, "mint: wrong price");

		_mintInternal(request);
	}

	/**
	 * mint many items
	 */
	function mintMany(MintManyRequest memory request, bytes calldata signature) public payable {
		require(canMintMany(request, signature), "mintMany: invalid");

		uint256 price = LandStorage._getPrice();
		uint256 count = 0;
		for (uint256 i = 0; i < request.count.length; i++) {
			count += request.count[i];
		}
		require(msg.value == price * count, "mintMany: wrong price");

		_mintManyInternal(request);
	}
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.18;

import "./BaseTokenURI.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IDelegationRegistry.sol";

contract Toobins is ERC721, Ownable, BaseTokenURI {
	using Strings for uint256;

	constructor(
		address _moonbirds,
		address _delegationRegistry,
		string memory _baseTokenURI
	) ERC721('Toobins', 'TOOBINS') BaseTokenURI(_baseTokenURI) {
		moonbirds = _moonbirds;
		delegationRegistry = IDelegationRegistry(_delegationRegistry);
	}

	address immutable moonbirds;
	IDelegationRegistry immutable delegationRegistry;
	uint256 public idTracker;

	/**
   @notice Does not enforce any transfer checks.
   */
	function initiate(address luckyFirst) public onlyOwner {
		assert(idTracker == 0);

		_mint(luckyFirst, idTracker++);
	}

	/**
   @notice Returns Toobins to the owner.
	@dev Charm is minted automatically in `_afterTokenTransfer` hook.
   */
	function yoink() public onlyOwner {
		_transfer(ownerOf(0), msg.sender, 0);
	}

	function _baseURI()
		internal
		view
		override(BaseTokenURI, ERC721)
		returns (string memory)
	{
		return baseTokenURI;
	}

	/**
   @notice Convenience Transfer function (without `from` or `tokenId`.)
   */
	function pass(address to) public {
		safeTransferFrom(msg.sender, to, 0);
	}

	/**
	@notice This is where the transfer checks happen.
	@dev Using hooks instead of overriding ERC-721 transfer functions.
   */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256
	) internal virtual override {
		if (
			// Always allow mints
			from == address(0) ||
			// Skip checks when owner yoinks
			to == owner()
		) {
			return;
		}

		require(
			tokenId == 0,
			'Charms are address-bound and cannot be transferred'
		);
		require(balanceOf(to) == 0, 'This address already received Toobins');
		require(
			_hasMoonbird(to) || _checkForMoonbirdsVault(to) != address(0),
			'Toobins can only be transferred to an address with a Moonbird'
		);
	}

	/**
	@notice This is where the mint happens after a transfer.
	The Charm is always minted in the same wallet that received Toobins.
	This follows the path of the Toobins, even if it was a delegate.
	@dev Does NOT use `_safeMint` as this allowed the Wriggler exploit.
	*/
	function _afterTokenTransfer(
		address from,
		address,
		uint256,
		uint256
	) internal virtual override {
		if (from != address(0)) {
			_mint(from, idTracker++);
		}
	}

	/**
	@notice Checks an address to see if it has a Moonbird.
	*/
	function _hasMoonbird(address owner) internal view returns (bool) {
		return IERC721(moonbirds).balanceOf(owner) > 0;
	}

	/**
	@notice Checks an address for any delegates relevant to Moonbirds.
	@return The first Moonbirds vault found, or address(0) if none found.
	*/
	function _checkForMoonbirdsVault(
		address delegate
	) internal view returns (address) {
		IDelegationRegistry.DelegationInfo[]
			memory delegateInfos = IDelegationRegistry(delegationRegistry)
				.getDelegationsByDelegate(delegate);

		for (uint256 i = 0; i < delegateInfos.length; i++) {
			IDelegationRegistry.DelegationInfo memory info = delegateInfos[i];

			// Filter out delegations that are not relevant to Moonbirds
			if (info.type_ == IDelegationRegistry.DelegationType.NONE) {
				continue;
			}
			if (
				info.type_ == IDelegationRegistry.DelegationType.TOKEN &&
				info.contract_ != moonbirds
			) {
				continue;
			}
			if (
				info.type_ == IDelegationRegistry.DelegationType.CONTRACT &&
				info.contract_ != moonbirds
			) {
				continue;
			}

			if (_hasMoonbird(info.vault)) {
				return info.vault;
			}
		}

		return address(0);
	}
}

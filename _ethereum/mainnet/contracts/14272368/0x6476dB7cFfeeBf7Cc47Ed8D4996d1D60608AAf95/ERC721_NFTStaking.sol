// SPDX-License-Identifier: AGPL-1.0-only
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721_NFT.sol";
import "./IERC721.sol";

/// @custom:security-contact privacy-admin@supremacy.game
contract Staking is Ownable {
	// track staked Token IDs to addresses to return to
	struct stakingStatus {
		address stakedBy;
		bool locked;
	}
	mapping(address => mapping(uint256 => stakingStatus)) public records;

	constructor() {}

	// remap changes the owner of an NFT
	// is used reconcile multiple transfers that have happened offchain
	function remap(
		address collection,
		uint256 tokenId,
		address newAddr
	) public onlyOwner {
		records[collection][tokenId].stakedBy = newAddr;
		emit Remap(collection, tokenId, newAddr);
	}

	// lock prevents change owners of an NFT
	function lock(address collection, uint256 tokenId) public onlyOwner {
		records[collection][tokenId].locked = true;
		emit Lock(collection, tokenId);
	}

	// unlock allows changing owners of an NFT
	function unlock(address collection, uint256 tokenId) public onlyOwner {
		records[collection][tokenId].locked = false;
		emit Unlock(collection, tokenId);
	}

	// stake registers the asset into the game
	function stake(address collection, uint256 tokenId) public {
		IERC721 nftContract = ERC721(collection);
		require(
			nftContract.ownerOf(tokenId) == msg.sender,
			"you are not the owner of this token"
		);
		nftContract.transferFrom(msg.sender, address(this), tokenId);
		records[collection][tokenId].stakedBy = msg.sender;
		emit Staked(collection, msg.sender, tokenId);
	}

	// unstake deregisters the asset from the game
	function unstake(address collection, uint256 tokenId) public {
		IERC721 nftContract = ERC721(collection);
		address to = records[collection][tokenId].stakedBy;
		require(!records[collection][tokenId].locked, "token is locked");
		require(to == msg.sender, "you are not the staker");
		nftContract.transferFrom(address(this), to, tokenId);
		records[collection][tokenId].stakedBy = address(0x0);
		emit Unstaked(collection, to, tokenId);
	}

	event Lock(address collection, uint256 tokenId);
	event Unlock(address collection, uint256 tokenId);
	event Remap(address collection, uint256 tokenId, address newAddr);
	event Staked(address collection, address owner, uint256 tokenId);
	event Unstaked(address collection, address owner, uint256 tokenId);
}

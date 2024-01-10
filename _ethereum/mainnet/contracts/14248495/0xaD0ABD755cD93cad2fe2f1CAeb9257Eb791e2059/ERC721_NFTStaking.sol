// SPDX-License-Identifier: AGPL-1.0-only
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721_NFT.sol";
import "./IERC721.sol";

/// @custom:security-contact privacy-admin@supremacy.game
contract Staking is Ownable {
	IERC721 private immutable SupNFTContract;

	// track staked Token IDs to addresses to return to
	mapping(uint256 => address) public StakedIDs;
	mapping(uint256 => bool) public LockedIDs;

	constructor(address _nftContract) {
		SupNFTContract = ERC721(_nftContract);
	}

	// remap changes the owner of an NFT
	// is used reconcile multiple transfers that have happened offchain
	function remap(uint256 tokenId, address newAddr) public onlyOwner {
		StakedIDs[tokenId] = newAddr;
		emit Remap(tokenId, newAddr);
	}

	// lock prevents change owners of an NFT
	function lock(uint256 tokenId) public onlyOwner {
		LockedIDs[tokenId] = true;
		emit Lock(tokenId);
	}

	// unlock allows changing owners of an NFT
	function unlock(uint256 tokenId) public onlyOwner {
		LockedIDs[tokenId] = false;
		emit Unlock(tokenId);
	}

	// stake registers the asset into the game
	function stake(uint256 tokenId) public {
		SupNFTContract.transferFrom(msg.sender, address(this), tokenId);
		StakedIDs[tokenId] = msg.sender;
		emit Staked(msg.sender, tokenId);
	}

	// unstake deregisters the asset from the game
	function unstake(uint256 tokenId) public {
		address to = StakedIDs[tokenId];
		require(!LockedIDs[tokenId], "token is locked");
		require(to == msg.sender, "you are not the staker");
		SupNFTContract.transferFrom(address(this), to, tokenId);
		StakedIDs[tokenId] = address(0x0);
		emit Unstaked(to, tokenId);
	}

	event Lock(uint256 tokenId);
	event Unlock(uint256 tokenId);
	event Remap(uint256 tokenId, address newAddr);
	event Staked(address owner, uint256 tokenId);
	event Unstaked(address owner, uint256 tokenId);
}

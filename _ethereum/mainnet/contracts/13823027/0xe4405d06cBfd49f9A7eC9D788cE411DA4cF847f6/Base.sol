// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IBucks.sol";
import "./IShop.sol";

interface ISpace {
	function getLife(uint256 tokenId)
		external
		view
		returns (
			uint256 job,
			uint256 task,
			uint256 data
		);
}

abstract contract AtopiaBase is ERC721 {
	uint256 constant apeYear = 365 days / 10;

	IBucks public bucks;
	address public shop;
	ISpace public space;

	mapping(uint256 => uint256) public infos;
	mapping(uint256 => uint256) public grow;

	function initialize(address _bucks) public virtual {
		name = "Atopia Apes";
		symbol = "ATPAPE";
		bucks = IBucks(_bucks);
	}

	function getRewardsInternal(
		uint256 tokenId,
		uint256 info,
		uint256 timestamp
	) internal view returns (uint256) {
		if (info == 0) return 0;
		uint64 claims = uint64(info);
		uint256 duration = timestamp - claims;
		uint256 averageSpeed = (timestamp + claims) / 2 + grow[tokenId] - (uint128(info) >> 64);
		return (averageSpeed * duration * 20_000_000) / apeYear / 1 days;
	}

	function getAge(uint256 tokenId) public view returns (uint256) {
		return (block.timestamp - (uint128(infos[tokenId]) >> 64)) + grow[tokenId];
	}

	function getReward(uint256 tokenId) internal view returns (uint256 pending, uint256 info) {
		(uint256 job, uint256 task, ) = space.getLife(tokenId);
		info = infos[tokenId];
		pending = info >> 128;
		if (job == 0 || task > 0) {
			pending += getRewardsInternal(tokenId, info, block.timestamp);
		}
	}

	function getRewards(uint256[] memory tokenIds) external view returns (uint256 rewards) {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			(uint256 pending, ) = getReward(tokenId);
			rewards += pending;
		}
	}

	function onlyTokenOwner(uint256 tokenId) public {
		require(ownerOf[tokenId] == msg.sender);
	}

	function updateInternal(uint256 tokenId) internal {
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint64 claims = uint64(info);
		uint128 birth = (uint128(info) >> 64);
		uint256 duration = timestamp - claims;
		uint256 average = ((timestamp + claims) >> 1) + grow[tokenId] - birth;
		uint256 pending = (info >> 128) + (average * duration * 20_000_000) / apeYear / 1 days;
		infos[tokenId] = (pending << 128) | (birth << 64) | uint64(timestamp);
	}

	function claimRewards(uint256[] memory tokenIds) public {
		uint256 timestamp = block.timestamp;
		uint256 rewards;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			require(ownerOf[tokenId] == msg.sender);
			(uint256 pending, uint256 info) = getReward(tokenId);
			if (pending > 0) {
				rewards += pending;
				infos[tokenId] = ((uint128(info) >> 64) << 64) | uint64(timestamp);
			}
		}
		if (rewards > 0) {
			bucks.mint(msg.sender, rewards);
		}
	}

	function useItemInternal(uint256 tokenId, uint256 bonusAge) internal {
		updateInternal(tokenId);
		grow[tokenId] += bonusAge;
	}

	function update(uint256 tokenId) external {
		require(address(space) == msg.sender);
		updateInternal(tokenId);
	}

	function exitCenter(
		uint256 tokenId,
		address center,
		uint256 grown,
		uint256 enjoyFee
	) external {
		require(address(space) == msg.sender);
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint256 rewards = getRewardsInternal(tokenId, info, timestamp);
		uint256 fee = (rewards * enjoyFee) / 10000;
		uint256 pending = (infos[tokenId] >> 128) + (rewards - fee);
		infos[tokenId] = (pending << 128) | ((uint128(info) >> 64) << 64) | uint64(timestamp);
		grow[tokenId] += grown;
		bucks.mint(center, fee);
	}

	function setShop(address _shop) external onlyOwner {
		shop = _shop;
		emit ShopUpdated(_shop);
	}

	function setSpace(address _space) external onlyOwner {
		space = ISpace(_space);
		emit SpaceUpdated(_space);
	}

	function _beforeTokenTransfer(
		address,
		address,
		uint256 tokenId
	) internal virtual override {
		uint256 timestamp = block.timestamp;
		(uint256 pending, uint256 info) = getReward(tokenId);
		if (pending > 0) {
			infos[tokenId] = ((uint128(info) >> 64) << 64) | uint64(timestamp);
			bucks.mint(ownerOf[tokenId], pending);
		}
	}

	event DrawerUpdated(address drawer);
	event ShopUpdated(address shop);
	event SpaceUpdated(address space);
}

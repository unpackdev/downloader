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

	function totalCenters() external view returns (uint256);

	function addFeeAmount(uint256 centerId, uint256 amount) external;

	function grow(uint256 centerId, uint256 tokenId) external;

	function getGrowthAndFee(
		uint256 centerId,
		uint256 tokenId,
		uint256 growingReward
	) external view returns (uint256 grown, uint256 fee);
}

abstract contract AtopiaBase is ERC721 {
	uint256 constant apeYear = 365 days / 10;

	IBucks public bucks;
	address public shop;
	ISpace public space;

	mapping(uint256 => uint256) public infos;
	mapping(uint256 => uint256) public retiredGrow; // retire

	function initialize(address _bucks) public virtual {
		name = "Atopia Apes";
		symbol = "ATPAPE";
		bucks = IBucks(_bucks);
	}

	function getRewardsInternal(uint256 info, uint256 timestamp) internal pure returns (uint256) {
		if (info == 0) return 0;
		uint64 claims = uint64(info);
		uint256 duration = timestamp - claims;
		uint256 averageSpeed = (timestamp + claims) / 2 + uint64(info >> 192) - (uint128(info) >> 64);
		return (averageSpeed * duration * 20_000_000) / apeYear / 1 days;
	}

	function getAge(uint256 tokenId) public view returns (uint256) {
		uint256 info = infos[tokenId];
		return (block.timestamp - (uint128(info) >> 64)) + (info >> 192);
	}

	function getReward(uint256 tokenId)
		public
		view
		returns (
			uint256 reward,
			uint256 info,
			uint256 centerId,
			uint256 fee,
			uint256 grown
		)
	{
		(uint256 job, uint256 task, ) = space.getLife(tokenId);
		info = infos[tokenId];
		reward = uint64(info >> 128);
		uint256 growingReward = getRewardsInternal(info, block.timestamp);
		if (job > 0 && task == 0) {
			centerId = job;
			(grown, fee) = space.getGrowthAndFee(centerId, tokenId, growingReward);
		}
		reward += growingReward;
	}

	function getRewards(uint256[] memory tokenIds) external view returns (uint256 rewards) {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			(uint256 reward, , , uint256 fee, ) = getReward(tokenId);
			rewards += (reward - fee);
		}
	}

	function onlyTokenOwner(uint256 tokenId) public view {
		require(ownerOf[tokenId] == msg.sender);
	}

	function claimRewards(uint256[] memory tokenIds) public {
		uint256 timestamp = block.timestamp;
		uint256 rewards;
		uint256[] memory fees = new uint256[](space.totalCenters());
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			onlyTokenOwner(tokenId);
			(uint256 reward, uint256 info, uint256 centerId, uint256 fee, uint256 grown) = getReward(tokenId);
			if (fee > 0) {
				reward -= fee;
				fees[centerId - 1] += fee;
				space.grow(centerId, tokenId);
			}
			rewards += reward;
			infos[tokenId] = (((info >> 192) + grown) << 192) | ((uint128(info) >> 64) << 64) | uint64(timestamp);
		}
		for (uint256 i = 0; i < fees.length; i++) {
			uint256 fee = fees[i];
			if (fee > 0) {
				space.addFeeAmount(i + 1, fee);
			}
		}
		bucks.mint(msg.sender, rewards);
	}

	function useItemInternal(uint256 tokenId, uint256 bonusAge) internal {
		(uint256 centerId, uint256 task, ) = space.getLife(tokenId);
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint256 growingReward = getRewardsInternal(info, timestamp);
		uint256 fee;
		uint256 grown;
		if (centerId > 0 && task == 0) {
			(grown, fee) = space.getGrowthAndFee(centerId, tokenId, growingReward);
			space.grow(centerId, tokenId);
			space.addFeeAmount(centerId, fee);
		}
		uint256 pending = growingReward + uint64(info >> 128) - fee;
		infos[tokenId] =
			(((info >> 192) + grown + bonusAge) << 192) |
			(pending << 128) |
			((uint128(info) >> 64) << 64) |
			uint64(timestamp);
	}

	function onlySpace() internal view {
		require(address(space) == msg.sender);
	}

	function claimGrowth(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256) {
		onlySpace();
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint256 rewards = getRewardsInternal(info, timestamp);
		uint256 fee = (rewards * enjoyFee) / 10000;
		uint256 pending = rewards + uint64(info >> 128) - fee;
		infos[tokenId] =
			(((info >> 192) + grown) << 192) |
			(pending << 128) |
			((uint128(info) >> 64) << 64) |
			uint64(timestamp);
		return fee;
	}

	function addReward(uint256 tokenId, uint256 reward) external {
		onlySpace();
		uint256 info = infos[tokenId];
		uint256 pending = uint64(info >> 128) + reward;
		infos[tokenId] = ((info >> 192) << 192) | (pending << 128) | ((uint128(info) >> 64) << 64) | uint64(info);
	}

	function claimBucks(address user, uint256 amount) external {
		onlySpace();
		bucks.mint(user, amount);
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
		(uint256 reward, uint256 info, uint256 centerId, uint256 fee, uint256 grown) = getReward(tokenId);
		if (fee > 0) {
			reward -= fee;
			space.addFeeAmount(centerId, fee);
			space.grow(centerId, tokenId);
		}
		infos[tokenId] = (((info >> 192) + grown) << 192) | ((uint128(info) >> 64) << 64) | uint64(timestamp);
		bucks.mint(ownerOf[tokenId], reward);
	}

	event DrawerUpdated(address drawer);
	event ShopUpdated(address shop);
	event SpaceUpdated(address space);
}

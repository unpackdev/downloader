// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./IAtopia.sol";
import "./ICenter.sol";

contract AtopiaSpace is ERC721 {
	bool public initialized;
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	struct Task {
		uint256 id;
		uint256 info;
		uint256 rewards;
	}

	IAtopia public atopia;
	ICenter[] public centers;
	mapping(uint256 => uint256) public lives;

	Task[] public tasks;

	event TaskUpdated(Task task);
	event LifeUpdated(uint256 tokenId, uint256 life);

	function initialize(address _atopia) public {
		require(!initialized);
		initialized = true;
		name = "Atopia Space";
		symbol = "ATPSPACE";
		atopia = IAtopia(_atopia);
	}

	modifier onlyAtopia() {
		require(msg.sender == atopia.owner());
		_;
	}

	function onlyTokenOwner(uint256 tokenId) public view {
		require(atopia.ownerOf(tokenId) == msg.sender);
	}

	function totalTasks() external view returns (uint256) {
		return tasks.length;
	}

	function totalCenters() external view returns (uint256) {
		return centers.length;
	}

	function getLife(uint256 tokenId)
		public
		view
		returns (
			uint256 job,
			uint256 task,
			uint256 data
		)
	{
		uint256 life = lives[tokenId];
		data = life & ((1 << 129) - 1);
		life = life >> 128;
		task = life & 0xFFFF;
		job = life >> 64;
	}

	function addTask(
		uint128 duration,
		uint128 minAge,
		uint256 rewards
	) external onlyAtopia {
		Task memory newTask = Task(tasks.length + 1, (uint256(duration) << 128) | minAge, rewards);
		tasks.push(newTask);
		emit TaskUpdated(newTask);
	}

	function updateTask(
		uint256 id,
		uint128 duration,
		uint128 minAge,
		uint256 rewards
	) external onlyAtopia {
		uint256 index = id - 1;
		tasks[index].info = (uint256(duration) << 128) | minAge;
		tasks[index].rewards = rewards;
		emit TaskUpdated(tasks[index]);
	}

	function addCenter(address center) external onlyAtopia {
		ICenter newCenter = ICenter(center);
		centers.push(newCenter);
		uint256 id = centers.length;
		_mint(msg.sender, id);
		newCenter.setId(id);
	}

	function addFeeAmount(uint256 centerId, uint256 amount) external {
		require(msg.sender == address(atopia));
		centers[centerId - 1].addFeeAmount(amount);
	}

	function enterInternal(uint256 tokenId, uint256 centerId) internal {
		(uint256 job, uint256 task, ) = getLife(tokenId);
		if (job != 0) {
			// already in a center for enjoying or working
			if (task != 0) {
				// if working quit work
				workInternal(tokenId, centerId, 0);
			} else {
				require(job != centerId);
				exit(tokenId);
			}
		}
		//require(lives[tokenId] == 0);
		//atopia.update(tokenId);
		lives[tokenId] = centers[centerId - 1].enter(tokenId);
		emit LifeUpdated(tokenId, lives[tokenId]);
	}

	function enter(uint256 tokenId, uint256 centerId) external {
		onlyTokenOwner(tokenId);
		enterInternal(tokenId, centerId);
	}

	struct EnterInfo {
		uint256 centerId;
		uint256[] tokenIds;
	}

	function batchEnter(EnterInfo[] memory enterInfos) external {
		for (uint256 i = 0; i < enterInfos.length; i++) {
			EnterInfo memory enterInfo = enterInfos[i];
			for (uint256 j = 0; j < enterInfo.tokenIds.length; j++) {
				uint256 tokenId = enterInfo.tokenIds[j];
				onlyTokenOwner(tokenId);
				enterInternal(tokenId, enterInfo.centerId);
			}
		}
	}

	function grow(uint256 centerId, uint256 tokenId) external {
		require(msg.sender == address(atopia));
		centers[centerId - 1].grow(tokenId);
	}

	function getGrowthAndFee(
		uint256 centerId,
		uint256 tokenId,
		uint256 growingReward
	) external view returns (uint256 grown, uint256 fee) {
		ICenter center = centers[centerId - 1];
		fee = (growingReward * center.enjoyFee()) / 10000;
		grown = center.grown(tokenId);
	}

	function exit(uint256 tokenId) public {
		onlyTokenOwner(tokenId);
		(uint256 job, uint256 task, ) = getLife(tokenId);
		require(job > 0 && task == 0);
		uint256 centerIndex = job - 1;
		uint256 feeAmount = atopia.claimGrowth(
			tokenId,
			centers[centerIndex].exit(tokenId),
			centers[centerIndex].enjoyFee()
		);
		lives[tokenId] = 0;
		if (feeAmount > 0) centers[centerIndex].addFeeAmount(feeAmount);
		emit LifeUpdated(tokenId, 0);
	}

	function batchExit(uint256[] memory tokenIds, uint256 centerId) external {
		uint256 centerIndex = centerId - 1;
		ICenter center = centers[centerIndex];
		uint256 feeAmount;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			(uint256 job, uint256 task, ) = getLife(tokenId);
			require(job == centerId && task == 0 && atopia.ownerOf(tokenId) == msg.sender);
			feeAmount += atopia.claimGrowth(tokenId, center.exit(tokenId), center.enjoyFee());
			lives[tokenId] = 0;
			emit LifeUpdated(tokenId, 0);
		}
		if (feeAmount > 0) center.addFeeAmount(feeAmount);
	}

	function claimGrowth(uint256[] memory tokenIds, uint256 centerId) public {
		uint256 centerIndex = centerId - 1;
		ICenter center = centers[centerIndex];
		uint256 feeAmount;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			(uint256 job, uint256 task, ) = getLife(tokenId);
			require(job == centerId && task == 0);
			feeAmount += atopia.claimGrowth(tokenId, center.grow(tokenId), center.enjoyFee());
		}
		if (feeAmount > 0) center.addFeeAmount(feeAmount);
	}

	function workInternal(
		uint256 tokenId,
		uint256 centerId,
		uint16 task
	) internal {
		uint256 life = lives[tokenId];
		uint256 job = life >> 128;
		uint256 currentTask = uint16(job);
		uint256 reward;
		job = job >> 64;
		if (task > 0) {
			//require(job == 0 || job == centerId);
			if (job != 0) {
				// if enjoying or already working
				if (currentTask == 0) {
					// if enjoying
					exit(tokenId);
					life = 0;
				} else if (job != centerId) {
					// if working
					(, reward) = centers[job - 1].work(tokenId, 0, life);
					life = 0;
				}
			}
			(life, reward) = centers[centerId - 1].work(tokenId, task, life);
		} else {
			// quit work
			require(job == centerId && currentTask > 0);
			(, reward) = centers[centerId - 1].work(tokenId, task, life);
			life = 0;
		}
		lives[tokenId] = life;
		if (reward > 0) atopia.addReward(tokenId, reward);
		emit LifeUpdated(tokenId, life);
	}

	function work(
		uint256 tokenId,
		uint256 centerId,
		uint16 task
	) external {
		onlyTokenOwner(tokenId);
		workInternal(tokenId, centerId, task);
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return centers[tokenId - 1].metadata();
	}

	function claimBucks(uint256 centerId, uint256 amount) external {
		require(msg.sender == address(centers[centerId - 1]));
		atopia.claimBucks(ownerOf[centerId], amount);
	}
}

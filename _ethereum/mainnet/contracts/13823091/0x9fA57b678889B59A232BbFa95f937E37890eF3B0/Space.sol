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

	modifier onlyTokenOwner(uint256 tokenId) {
		require(atopia.ownerOf(tokenId) == msg.sender);
		_;
	}

	modifier onlyAtopia() {
		require(msg.sender == atopia.owner());
		_;
	}

	function totalTasks() external view returns(uint256) {
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

	function addTask(uint128 duration, uint128 minAge, uint256 rewards) external onlyAtopia {
		Task memory newTask = Task(tasks.length + 1, (uint256(duration) << 128) | minAge, rewards);
		tasks.push(newTask);
		emit TaskUpdated(newTask);
	}

	function updateTask(uint256 id, uint128 duration, uint128 minAge, uint256 rewards) external onlyAtopia {
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

	function enter(uint256 tokenId, uint256 centerId) external onlyTokenOwner(tokenId) {
		require(lives[tokenId] == 0);
		atopia.update(tokenId);
		lives[tokenId] = centers[centerId - 1].enter(tokenId);
		emit LifeUpdated(tokenId, lives[tokenId]);
	}

	function exit(uint256 tokenId, uint256 centerId) external onlyTokenOwner(tokenId) {
		(uint256 job, uint256 task, ) = getLife(tokenId);
		require(job == centerId && task == 0);
		uint256 centerIndex = centerId - 1;
		atopia.exitCenter(
			tokenId,
			address(centers[centerIndex]),
			centers[centerIndex].exit(tokenId),
			centers[centerIndex].enjoyFee()
		);
		lives[tokenId] = 0;
		emit LifeUpdated(tokenId, 0);
	}

	function work(
		uint256 tokenId,
		uint256 centerId,
		uint16 task
	) external onlyTokenOwner(tokenId) {
		(uint256 job, uint256 currentTask, ) = getLife(tokenId);
		uint256 life;
		if (task > 0) {
			require(job == 0 || job == centerId);
			life = centers[centerId - 1].work(tokenId, task, lives[tokenId]);
		} else {
			require(job == centerId && currentTask > 0);
			centers[centerId - 1].work(tokenId, task, lives[tokenId]);
		}
		lives[tokenId] = life;
		emit LifeUpdated(tokenId, life);
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return centers[tokenId - 1].metadata();
	}
}

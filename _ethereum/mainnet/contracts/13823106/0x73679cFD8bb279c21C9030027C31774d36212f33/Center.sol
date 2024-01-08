// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISpace.sol";
import "./Base64.sol";

abstract contract AtopiaCenter {
	address implementation_;
	address public admin;

	bool public initialized;
	using Base64 for *;

	struct Package {
		uint256 id;
		string name;
		uint256 info;
		uint256 rewards;
	}

	uint16 public constant FEE_PERCENT = 500;
	uint16 public constant WORK_PERCENT = 1000;

	uint256 public id;
	string public name;
	string public description;
	string public image;
	uint256 public emission;
	uint256 public minAge;
	uint16 public enjoyFee;

	uint256 public level;
	uint256 public progress;

	ISpace public space;

	uint256 public workAvailable;
	Package[] public packages;
	mapping(uint256 => uint256) public workRewards;

	uint256 public totalStaking;
	mapping(uint256 => uint256) public claims;
	uint256 public currentReflection;
	uint256 public lastUpdateAt;

	event PackageAdded(Package newPackage);
	event LevelUpdated(uint256 level);

	function initialize(address _space) public virtual;

	function init(
		address _space,
		string memory _name,
		string memory _description
	) internal {
		require(!initialized);
		initialized = true;
		space = ISpace(_space);
		name = _name;
		description = _description;
	}

	modifier onlyOwner() {
		require(space.ownerOf(id) == msg.sender);
		_;
	}

	modifier onlySpace() {
		require(address(space) == msg.sender);
		_;
	}

	function totalPackages() external view returns (uint256) {
		return packages.length;
	}

	function newReflection() public view returns (uint256) {
		return currentReflection + (emission / totalStaking) * (block.timestamp - lastUpdateAt);
	}

	function grown(uint256 tokenId) public view returns (uint256) {
		return newReflection() - claims[tokenId];
	}

	function rewards(uint256 tokenId) public view returns (uint256) {
		return workRewards[tokenId];
	}

	function getProgress() public view returns (uint256) {
		uint256 percent = progress / emission;
		return percent > 100 ? 100 : percent;
	}

	function updateReflection() internal {
		if (totalStaking > 0) {
			currentReflection += (emission / totalStaking) * (block.timestamp - lastUpdateAt);
		}
		lastUpdateAt = block.timestamp;
	}

	function setId(uint256 _id) external onlySpace {
		require(address(space) == msg.sender);
		require(id == 0);
		id = _id;
	}

	function enter(uint256 tokenId) external onlySpace returns (uint256) {
		require(space.atopia().getAge(tokenId) >= minAge);
		updateReflection();
		totalStaking += 1;
		claims[tokenId] = currentReflection;
		return id << 192;
	}

	function exit(uint256 tokenId) external onlySpace returns (uint256 _growing) {
		_growing = grown(tokenId);
		totalStaking -= 1;
		updateReflection();
	}

	function work(
		uint256 tokenId,
		uint16 packageId,
		uint256 working
	) external onlySpace returns (uint256) {
		if (packageId > 0) {
			uint16 package = packageId - 1;
			require(package < packages.length);
			require(space.atopia().getAge(tokenId) >= uint128(packages[package].info));
			require(packages[package].rewards <= workAvailable);

			if (working > 0) {
				uint16 currentPackage = uint16(working >> 128) - 1;
				uint256 end = working & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
				require(block.timestamp >= end);
				workRewards[tokenId] += packages[currentPackage].rewards;
			}

			workAvailable -= packages[package].rewards;
			return (id << 192) | (uint256(packageId) << 128) | (block.timestamp + (packages[package].info >> 128));
		} else {
			require(working > 0);

			uint16 currentPackage = uint16(working >> 128) - 1;
			uint256 end = working & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
			uint256 totalRewards = 0;
			if (block.timestamp >= end) {
				totalRewards += packages[currentPackage].rewards;
			} else {
				workAvailable += packages[currentPackage].rewards;
			}

			if (workRewards[tokenId] > 0) {
				totalRewards += workRewards[tokenId];
				workRewards[tokenId] = 0;
			}

			if (totalRewards > 0) {
				space.atopia().bucks().transfer(space.atopia().ownerOf(tokenId), totalRewards);
				progress += totalRewards;
			}

			return totalRewards;
		}
	}

	function addPackage(string memory packageName, uint256 taskId) external onlyOwner {
		Task memory task = space.tasks(taskId);
		Package memory newPackage = Package(packages.length + 1, packageName, task.info, task.rewards);
		packages.push(newPackage);
		emit PackageAdded(newPackage);
	}

	function upgrade() external onlyOwner {
		require(getProgress() == 100);
		progress -= emission * 100;
		emission = (emission * 110) / 100;
		level += 1;
		emit LevelUpdated(level);
	}

	function withdraw() external onlyOwner {
		uint256 bucks = space.atopia().bucks().balanceOf(address(this)) - workAvailable;
		uint256 fee = (bucks * FEE_PERCENT) / 10000;
		uint256 newWork = (bucks * WORK_PERCENT) / 10000;
		workAvailable += newWork;
		space.atopia().bucks().burn(bucks - fee - newWork);
		space.atopia().bucks().transfer(msg.sender, fee);
	}

	function metadata() external view returns (string memory) {
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name":"',
							name,
							'","description":"',
							description,
							'","image":"data:image/svg+xml;base64,',
							Base64.encode(bytes(image)),
							'","attributes":[{"display_type":"number","trait_type":"Emission","value":"',
							emission.toString(),
							'"},{"display_type":"number","trait_type":"Min Age","value":"',
							((minAge * 10) / 365 days).toString(),
							'"},{"trait_type":"Level","value":"',
							level.toString(),
							'"},{"display_type":"boost_percentage","trait_type":"Progress","value":"',
							getProgress().toString(),
							'"},{"display_type":"boost_percentage","trait_type":"Fee","value":"',
							(enjoyFee / 100).toString(),
							'"}]}'
						)
					)
				)
			);
	}
}

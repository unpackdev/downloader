// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Spawner.sol";
import "./PondCoin.sol";
import "./IActiveChecker.sol";
import "./ISpawnManager.sol";
import "./ExecutorManager.sol";

contract SpawnManager is ISpawnManager, ExecutorManager {
    event SpawnCreated(address indexed spawnContract, uint256 createdIndex);

    error InvalidSpawnIndex();
    error NotSetup();

    IActiveChecker public spawnActiveChecker;
    IERC20 public spawnedCoin;
    IERC20 public spawnedFromCoin;

    uint256 public spawnIndex;
    mapping(uint256 => Spawner) public spawners;

    uint256 public spawnLastsFor = 69 minutes;
    uint256 public inactiveUserNumerator;
    uint256 public rewardCoinRateNumerator;

    constructor() {
        _addExecutor(msg.sender);
    }

    modifier validSpawnIndex(uint256 index) {
        if (index == 0 || index > spawnIndex) revert InvalidSpawnIndex();
        _;
    }

    modifier onlyWhenSetup() {
        if (inactiveUserNumerator == 0 || rewardCoinRateNumerator == 0) revert NotSetup();
        _;
    }

    function updateConfig(
        IActiveChecker _spawnActiveChecker,
        IERC20 _spawnedCoin,
        IERC20 _spawnedFromCoin,
        uint256 _spawnLastsFor,
        uint256 _inactiveUserNumerator,
        uint256 _rewardCoinRateNumerator
    ) onlyExecutor external {
        spawnActiveChecker = _spawnActiveChecker;
        spawnedCoin = _spawnedCoin;
        spawnedFromCoin = _spawnedFromCoin;
        spawnLastsFor = _spawnLastsFor;
        inactiveUserNumerator = _inactiveUserNumerator;
        rewardCoinRateNumerator = _rewardCoinRateNumerator;
    }

    function deposit(IERC20 _toDeposit, uint256 amount) onlyExecutor external {
        require(_toDeposit.transferFrom(msg.sender, address(this), amount));
    }

    function withdraw(IERC20 _toWithdraw, uint256 amount) onlyExecutor external {
        require(_toWithdraw.transferFrom(address(this), msg.sender, amount));
    }

    function createSpawn(uint256 spawnAmount) onlyWhenSetup onlyExecutor external {
        Spawner createdSpawner = new Spawner(
            spawnActiveChecker,
            spawnedFromCoin,
            spawnedCoin,
            spawnAmount,
            block.timestamp + spawnLastsFor,
            inactiveUserNumerator,
            rewardCoinRateNumerator
        );

        spawnedCoin.approve(address(createdSpawner), type(uint256).max);

        uint256 newIndex = ++spawnIndex; 

        spawners[newIndex] = createdSpawner;

        emit SpawnCreated(address(createdSpawner), newIndex);
    }

    function getSpawner(uint256 index) validSpawnIndex(index) external view returns (address) {
        return(address(spawners[index]));
    }

    function end(uint256 index) validSpawnIndex(index) onlyExecutor external {
        spawners[index].end();
    }

    function spawnThrough(uint256 _spawnerIndex, uint256 _amount) external returns(uint256 spawnAmount) {
        require(spawners[_spawnerIndex].spawnFromContract().transferFrom(msg.sender, address(this), _amount));
        return(spawners[_spawnerIndex].deployerSpawn(msg.sender, _amount));
    }
}

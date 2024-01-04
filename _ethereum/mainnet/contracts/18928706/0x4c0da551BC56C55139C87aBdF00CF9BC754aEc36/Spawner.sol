// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IActiveChecker.sol";
import "./PondCoin.sol";
import "./MathHelpers.sol";
import "./ReentrancyGuard.sol";

contract Spawner is IPondCoinSpawner, MathHelpers, ReentrancyGuard {
    error NotDeployer();
    error CannotComputeZero();
    error IncorrectSpawnFrom();
    error CannotEndInPast();
    error NotOpen();
    error CannotEndWhileOpen();
    error CannotSpawnMore();
    error UnderMinimumSpawn();

    event Spawn(address indexed spawner, uint256 amount, bool userIsActive);

    address public deployer;

    IActiveChecker public activeChecker;
    IERC20 public spawnFromContract;
    IERC20 public spawnCoin;
    uint256 public closesAt;

    uint256 public canStillSpawn;
    uint256 public inactiveUserNumerator;
    uint256 public rewardCoinRateNumerator;
    uint256 public constant minimumSpawnAmount = 50_000_000;

    constructor(
        IActiveChecker _activeChecker,
        IERC20 _spawnFromContract,
        IERC20 _spawnCoin,
        uint256 _totalSpawnAmount,
        uint256 _closesAt,
        uint256 _inactiveUserNumerator,
        uint256 _rewardCoinRateNumerator
    ) {
        deployer = msg.sender;

        if (block.timestamp > _closesAt) revert CannotEndInPast();

        activeChecker = _activeChecker;
        spawnFromContract = _spawnFromContract;
        spawnCoin = _spawnCoin;
        closesAt = _closesAt;
        inactiveUserNumerator = _inactiveUserNumerator;
        rewardCoinRateNumerator = _rewardCoinRateNumerator;
        canStillSpawn = _totalSpawnAmount;
    }

    modifier whileOpen() {
        if (isOpen() != true) revert NotOpen();
        _;
    }

    modifier onlyDeployer() {
        if (msg.sender != deployer) revert NotDeployer();
        _;
    }

    function isOpen() public view returns(bool) {
        return(block.timestamp <= closesAt);
    }

    function checkAddressActive(address toCheck) public view returns(bool) {
        return(activeChecker.isActive(toCheck));
    }

    function computeRate(bool _isActive, uint256 _amount) public view returns(uint256) {
        uint256 computed = _amount;

        if (_isActive != true) {
            computed = _multiplyWithNumerator(computed, inactiveUserNumerator);
        }

        computed = _multiplyWithNumerator(computed, rewardCoinRateNumerator);

        if(computed <= 0) revert CannotComputeZero();

        return(computed);
    }

    function _spawn(address _spawner, uint256 _inputAmount) internal nonReentrant whileOpen returns(uint256 spawnAmount) {
        if (_inputAmount < minimumSpawnAmount) revert UnderMinimumSpawn();
        if (_inputAmount > canStillSpawn) revert CannotSpawnMore();
        canStillSpawn -= _inputAmount;

        bool isActive = checkAddressActive(_spawner);

        spawnAmount = computeRate(isActive, _inputAmount);

        require(spawnCoin.transferFrom(deployer, _spawner, spawnAmount));

        emit Spawn(_spawner, _inputAmount, isActive);

        return(spawnAmount);
    }

    function deployerSpawn(address _address, uint256 _amount) onlyDeployer() external returns(uint256 spawnAmount) {
        return(_spawn(_address, _amount));
    }

    function spawnDirect(uint256 _amount) external returns(uint256 spawnAmount) {
        require(spawnFromContract.transferFrom(msg.sender, deployer, _amount));
        return(_spawn(msg.sender, _amount));
    }

    function spawn(address _address, uint256 _amount) external returns(bool) {
        if (msg.sender != address(spawnFromContract)) revert IncorrectSpawnFrom();
        _spawn(_address, _amount);
        return(true);
    }

    function end() onlyDeployer external {
        if (isOpen() == true) revert CannotEndWhileOpen();
        spawnCoin.transferFrom(address(this), deployer, spawnCoin.balanceOf(address(this)));
    }
}

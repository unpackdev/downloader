// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20RewardApeV1.sol";
import "./IPoolManager.sol";

contract RewardApeFactoryV2 is Ownable {
    address public defaultOwner;

    event DeployedPoolContract(
        address indexed pool,
        address stakeToken,
        address rewardToken,
        uint256 rewardPerSecond,
        uint256 startTime,
        uint256 bonusEndTime,
        address owner
    );

    constructor(address _defaultOwner) {
        defaultOwner = _defaultOwner;
    }

    function deployDefaultPoolContract(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime
    ) public {
        deployPoolContract(
            _stakeToken,
            _rewardToken,
            _rewardPerSecond,
            _startTime,
            _bonusEndTime,
            defaultOwner
        );
    }

    function deployPoolContract(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime,
        address _owner
    ) public {
        ERC20RewardApeV1 pool = new ERC20RewardApeV1();

        pool.initialize(
            _stakeToken,
            _rewardToken,
            _rewardPerSecond,
            _startTime,
            _bonusEndTime
        );

        pool.transferOwnership(_owner);

        emit DeployedPoolContract(
            address(pool),
            address(_stakeToken),
            address(_rewardToken),
            _rewardPerSecond,
            _startTime,
            _bonusEndTime,
            _owner
        );
    }

    function deployComputedPoolContract(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _startTime,
        uint256 _secondsDuration,
        uint256 _totalRewards,
        address _owner
    ) public {
        (uint256 rewardPerSecond, uint256 bonusEndTime) = calculatedConfig(
            _totalRewards,
            _startTime,
            _secondsDuration
        );
        deployPoolContract(
            _stakeToken,
            _rewardToken,
            rewardPerSecond,
            _startTime,
            bonusEndTime,
            _owner
        );
    }

    function calculatedConfig(
        uint256 _totalRewards,
        uint256 _startTime,
        uint256 _secondsDuration
    ) public pure returns (uint256 rewardsPerSecond, uint256 bonusEndTime) {
        rewardsPerSecond = _totalRewards / _secondsDuration;
        bonusEndTime = _startTime + _secondsDuration;

        return (rewardsPerSecond, bonusEndTime);
    }

    function updateDefaultOwner(address _defaultOwner) public onlyOwner {
        defaultOwner = _defaultOwner;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Errors.sol";
import "./IBentPool.sol";
import "./IBentPoolManager.sol";
import "./IBentToken.sol";

contract BentPoolManagerUpgradeable is OwnableUpgradeable, IBentPoolManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PoolInfo {
        address lpToken;
        address pool;
    }

    struct FeeInfo {
        uint256 harvesterFee; // 10000 for denominator
        address bentStaker;
        uint256 bentStakerFee; // 10000 for denominator
        address cvxStaker;
        uint256 cvxStakerFee; // 10000 for denominator
    }

    mapping(address => uint256) private _poolIndex;
    PoolInfo[] public poolInfo;
    address public override rewardToken;

    FeeInfo public override feeInfo;

    function initialize(
        address _rewardToken
    ) public initializer {
        __Ownable_init();
        rewardToken = _rewardToken;
    }

    function add(address _pool) external onlyOwner {
        require(_poolIndex[_pool] == 0, Errors.ALREADY_EXISTS);

        poolInfo.push(
            PoolInfo({lpToken: IBentPool(_pool).lpToken(), pool: _pool})
        );
        _poolIndex[_pool] = poolInfo.length;

        IERC20Upgradeable(rewardToken).safeApprove(_pool, type(uint256).max);
    }

    function remove(address _pool) external onlyOwner {
        require(_poolIndex[_pool] != 0, Errors.INVALID_POOL_ADDRESS);

        uint256 pid = _poolIndex[_pool] - 1;
        poolInfo[pid].lpToken = address(0);
        poolInfo[pid].pool = address(0);
        _poolIndex[_pool] = 0;
    }

    function setFeeInfo(FeeInfo memory _feeInfo) external onlyOwner {
        feeInfo = _feeInfo;
    }

    function mint(address _user, uint256 _cvxAmount) external override {
        require(_poolIndex[msg.sender] != 0, Errors.UNAUTHORIZED);

        IBentToken(rewardToken).mint(_user, _cvxAmount);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function poolIndex(address _pool) external view returns (uint256) {
        require(_poolIndex[_pool] != 0, Errors.INVALID_POOL_ADDRESS);
        return _poolIndex[_pool] - 1;
    }

    function isPool(address _pool) external view returns (bool) {
        return _poolIndex[_pool] != 0;
    }
}

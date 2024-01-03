// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./IGFarming.sol";

contract GFarming is Ownable, IGFarming {
    using SafeMath for uint256;

    uint256 private _maxPoolsCount;
    uint256 private _rewardsPerBlock;
    bool private _lockForever;

    constructor(
        uint256 _maxPools,
        uint256 _rewards,
        bool _lock // default: false
    ) public {
        _maxPoolsCount = _maxPools;
        _rewardsPerBlock = _rewards; // decimals 18
        _lockForever = _lock;
    }

    function changeMaxPoolsCount(uint256 _maxPools) external override onlyOwner {
        require(_maxPools > 0, '[3501] GFARMING: invalid the value');
        _maxPoolsCount = _maxPools;
    }

    function changeRewardsPerBlock(uint256 _rewards) external override onlyOwner {
        require(_rewards > 0, '[3500] GFARMING: invalid the value');
        _rewardsPerBlock = _rewards; // decimals 18
    }

    function changeLockForever(bool _lock) external override onlyOwner {
        _lockForever = _lock; // default: false
    }

    function maxPools() public override view returns (uint256) {
        return _maxPoolsCount;
    }

    function rewardsPerBlock() public override view returns (uint256) {
        return _rewardsPerBlock;
    }

    function lockForever() public override view returns (bool) {
        return _lockForever;
    }
}

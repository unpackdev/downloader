// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IPoolExtension.sol";
import "./StakingPool.sol";

contract PoolManager is Ownable {
  uint256 constant FACTOR = 10000;
  address public DEXROUTER;

  address public stakingToken;
  uint256 _totalPercentages;
  bool public adminCanWithdraw = true;

  struct PoolInfo {
    address pool;
    uint256 percentage;
  }

  PoolInfo[] public pools;

  constructor(address _stakingToken, address _router) {
    DEXROUTER = _router;
    stakingToken = _stakingToken;
    _totalPercentages = FACTOR;

    pools.push(
      PoolInfo({
        pool: address(new StakingPool(_stakingToken, 1209600, DEXROUTER, 30)),
        percentage: (FACTOR * 3) / 100 // 3%
      })
    );
    
    pools.push(
      PoolInfo({
        pool: address(new StakingPool(_stakingToken, 2419200, DEXROUTER, 25)),
        percentage: (FACTOR * 17) / 100 // 12%
      })
    );

    pools.push(
      PoolInfo({
        pool: address(new StakingPool(_stakingToken, 4838400, DEXROUTER, 20)),
        percentage: (FACTOR * 80) / 100 // 85%
      })
    );
  }

  function getAllPools() external view returns (PoolInfo[] memory) {
    return pools;
  }

  function depositRewards() external payable {
    require(msg.value > 0, 'no rewards');
    uint256 _totalETH;
    for (uint256 _i; _i < pools.length; _i++) {
      uint256 _totalBefore = _totalETH;
      _totalETH += (msg.value * pools[_i].percentage) / FACTOR;
      StakingPool(pools[_i].pool).depositRewards{
        value: _totalETH - _totalBefore
      }();
    }
    uint256 _refund = msg.value - _totalETH;
    if (_refund > 0) {
      (bool _refunded, ) = payable(_msgSender()).call{ value: _refund }('');
      require(_refunded, 'could not refund');
    }
  }

  function claimRewardsBulk(
    bool[] memory _compound,
    uint256[] memory _minTokens
  ) external {
    for (uint256 _i; _i < _compound.length; _i++) {
      StakingPool(pools[_i].pool).claimRewardAdmin(
        _msgSender(),
        _compound[_i],
        _minTokens[_i]
      );
    }
  }

  function setLockupPeriods(uint256[] memory _seconds) external onlyOwner {
    for (uint256 _i; _i < _seconds.length; _i++) {
      StakingPool(pools[_i].pool).setLockupPeriod(_seconds[_i]);
    }
  }

  function setPercentages(uint256[] memory _percentages) external onlyOwner {
    _totalPercentages = 0;
    for (uint256 _i; _i < _percentages.length; _i++) {
      _totalPercentages += _percentages[_i];
      pools[_i].percentage = _percentages[_i];
    }
    require(_totalPercentages <= FACTOR, 'lte 100%');
  }

  function setExtension(IPoolExtension[] memory _ext) external onlyOwner {
    for (uint256 _i; _i < _ext.length; _i++) {
      StakingPool(pools[_i].pool).setPoolExtension(_ext[_i]);
    }
  }

  function setPenaltyFee(uint256[] memory _fee) external onlyOwner {
    for (uint256 _i; _i < _fee.length; _i++) {
      StakingPool(pools[_i].pool).setPenaltyFee(_fee[_i]);
    }
  }

  function setBurnAddress(address _burn) external onlyOwner {
    for (uint256 _i; _i < pools.length; _i++) {
      StakingPool(pools[_i].pool).setBurnAddress(_burn);
    }
  }

  function removeWithdrawAbility() external onlyOwner {
    require(adminCanWithdraw, 'already disabled');
    adminCanWithdraw = false;
  }

  function withdrawFromPools(uint256[] memory _amounts) external onlyOwner {
    require(adminCanWithdraw, 'disabled');
    for (uint256 _i; _i < _amounts.length; _i++) {
      StakingPool(pools[_i].pool).withdrawTokens(_amounts[_i]);
    }
  }

  function createPool(
    uint256 _lockupSeconds,
    uint256 _percentage,
    uint256 _penaltyFee
  ) external onlyOwner {
    require(_totalPercentages + _percentage <= FACTOR, 'max percentage');
    _totalPercentages += _percentage;
    pools.push(
      PoolInfo({
        pool: address(new StakingPool(stakingToken, _lockupSeconds, DEXROUTER, _penaltyFee)),
        percentage: _percentage
      })
    );
  }

  function removePool(uint256 _idx) external onlyOwner {
    PoolInfo memory _pool = pools[_idx];
    _totalPercentages -= _pool.percentage;
    pools[_idx] = pools[pools.length - 1];
    pools.pop();
  }

  function renounceAllOwnership() external onlyOwner {
    for (uint256 _i; _i < pools.length; _i++) {
      StakingPool(pools[_i].pool).renounceOwnership();
    }
    renounceOwnership();
  }
}
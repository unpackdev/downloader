// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IPoolManager.sol";
import "./StakingPool.sol";

contract PoolManager is IPoolManager, Ownable {
  using SafeERC20 for IERC20;

  uint256 constant DENOMENATOR = 10000;

  address public override stakingToken;
  address public rewardsToken;
  uint256 _totalPercentages;

  PoolInfo[] public pools;

  constructor(address _stakingToken, address _rewardsToken) {
    stakingToken = _stakingToken;
    rewardsToken = _rewardsToken;
    _totalPercentages = DENOMENATOR;
    pools.push(
      PoolInfo({
        pool: address(
          new StakingPool(
            'OPTI-XA',
            'OPTI-XA',
            _stakingToken,
            _rewardsToken,
            7 days
          )
        ),
        percentage: (DENOMENATOR * 15) / 100 // 15%
      })
    );
    pools.push(
      PoolInfo({
        pool: address(
          new StakingPool(
            'OPTI-XB',
            'OPTI-XB',
            _stakingToken,
            _rewardsToken,
            21 days
          )
        ),
        percentage: (DENOMENATOR * 35) / 100 // 35%
      })
    );
    pools.push(
      PoolInfo({
        pool: address(
          new StakingPool(
            'OPTI-XC',
            'OPTI-XC',
            _stakingToken,
            _rewardsToken,
            60 days
          )
        ),
        percentage: (DENOMENATOR * 50) / 100 // 50%
      })
    );
  }

  function getAllPools() external view override returns (PoolInfo[] memory) {
    return pools;
  }

  function depositNativeRewards() external payable {
    require(msg.value > 0, 'ETH');
    uint256 _totalETH;
    for (uint256 _i; _i < pools.length; _i++) {
      NativeRewards _nativeRewards = StakingPool(pools[_i].pool)
        .NATIVE_REWARDS();
      uint256 _totalBefore = _totalETH;
      _totalETH += (msg.value * pools[_i].percentage) / DENOMENATOR;
      _nativeRewards.depositRewards{ value: _totalETH - _totalBefore }();
    }
    uint256 _refund = msg.value - _totalETH;
    if (_refund > 0) {
      (bool _refunded, ) = payable(_msgSender()).call{ value: _refund }('');
      require(_refunded, 'REFUND');
    }
  }

  function depositTokenRewards(uint256 _totalAmount) external {
    uint256 _before = IERC20(rewardsToken).balanceOf(address(this));
    IERC20(rewardsToken).safeTransferFrom(
      _msgSender(),
      address(this),
      _totalAmount
    );
    uint256 _totalTokens = IERC20(rewardsToken).balanceOf(address(this)) -
      _before;
    for (uint256 _i; _i < pools.length; _i++) {
      TokenRewards _tokenRewards = StakingPool(pools[_i].pool).TOKEN_REWARDS();
      uint256 _poolAmount = (_totalTokens * pools[_i].percentage) / DENOMENATOR;
      IERC20(rewardsToken).safeIncreaseAllowance(
        address(_tokenRewards),
        _poolAmount
      );
      _tokenRewards.depositRewards(_poolAmount);
    }
    uint256 _refund = IERC20(rewardsToken).balanceOf(address(this)) - _before;
    if (_refund > 0) {
      IERC20(rewardsToken).safeTransfer(_msgSender(), _refund);
    }
  }

  function setTimelockSeconds(uint256[] memory _seconds) external onlyOwner {
    for (uint256 _i; _i < _seconds.length; _i++) {
      StakingPool(pools[_i].pool).setTimelockSeconds(_seconds[_i]);
    }
  }

  function setPercentages(uint256[] memory _percentages) external onlyOwner {
    _totalPercentages = 0;
    for (uint256 _i; _i < _percentages.length; _i++) {
      _totalPercentages += _percentages[_i];
      pools[_i].percentage = _percentages[_i];
    }
    require(_totalPercentages <= DENOMENATOR, 'lte 100%');
  }

  function createPool(
    string memory _name,
    string memory _symbol,
    uint256 _lockupSeconds,
    uint256 _percentage
  ) external onlyOwner {
    require(_totalPercentages + _percentage <= DENOMENATOR, 'MAX');
    _totalPercentages += _percentage;
    pools.push(
      PoolInfo({
        pool: address(
          new StakingPool(
            _name,
            _symbol,
            stakingToken,
            rewardsToken,
            _lockupSeconds
          )
        ),
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

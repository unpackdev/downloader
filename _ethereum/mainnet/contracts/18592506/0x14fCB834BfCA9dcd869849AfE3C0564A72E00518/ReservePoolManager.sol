// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IReservePool.sol";

contract ReservePoolManager is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  IERC20 public immutable token;
  address[] public pools;
  uint public poolsLength;

  address private singleAssetPool;

  constructor (
    address _token
  ) {
    token = IERC20(_token);
    _pause();
  }

  /** VIEW FUNCTIONS */

  function getTotalStaked() external view returns (uint[] memory amounts) {
    amounts = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      amounts[index] = IReservePool(pools[index]).totalSupply();
    }
  }

  function getTotalParticipants() external view returns (uint[] memory counts) {
    counts = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      counts[index] = IReservePool(pools[index]).totalParticipants();
    }
  }

  function getTotalRewards() external view returns (uint[] memory rewards) {
    rewards = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      rewards[index] = IReservePool(pools[index]).totalRewards();
    }
  }

  function getAprRates() external view returns (uint[] memory aprRates) {
    aprRates = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      aprRates[index] = IReservePool(pools[index]).aprRate();
    }
  }

  function earned(address account) public view returns (uint reward) {
    for (uint index = 0; index < poolsLength; index++) {
      reward = reward.add(IReservePool(pools[index]).earned(account));
    }
  }

  function getTotalClaimed(address account) external view returns (uint[] memory amounts) {
    amounts = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      amounts[index] = IReservePool(pools[index]).getTotalClaimed(account);
    }
  }

  function getUserStakes(address account) external view returns (uint[] memory stakes) {
    stakes = new uint[](poolsLength);
    for (uint index = 0; index < poolsLength; index++) {
      stakes[index] = IReservePool(pools[index]).balanceOf(account);
    }
  }

  function getRewardRate(address account) external view returns (uint rewardRate) {
    for (uint index = 0; index < poolsLength; index++) {
      rewardRate = rewardRate.add(IReservePool(pools[index]).getRewardRate(account));
    }
  }

  /** PUBLIC FUNCTIONS */

  function stake(address pool, uint amount) 
    external 
    whenNotPaused
    nonReentrant
  {
    _stake(pool, _msgSender(), amount, false);
  }

  function withdraw(address pool, uint amount) 
    external 
    nonReentrant 
  {
    _withdraw(pool, _msgSender(), amount);
  }

  function claim() 
    external 
    nonReentrant 
  {
    for (uint index = 0; index < poolsLength; index++) {
      IReservePool(pools[index]).claim(_msgSender(), false);
    }
  }

  function compound() 
    external
    nonReentrant 
  {
    uint reward = earned(_msgSender());

    if (reward > 0) {
      for (uint index = 0; index < poolsLength; index++) {
        IReservePool(pools[index]).claim(_msgSender(), true);
      }

      token.approve(singleAssetPool, reward);
      _stake(singleAssetPool, _msgSender(), reward, true);
    }
  }

  /** INTERNAL FUNCTIONS */

  function _stake(address pool, address account, uint amount, bool isCompound) 
    internal 
  {
    bool foundPool = false;

    for (uint i; i < poolsLength; i++) {
      if (pools[i] == pool) {
        foundPool = true;
        break;
      }
    }

    require(foundPool, "Pool doesn't exists");

    IReservePool(pool).stake(account, amount, isCompound);
  }

  function _withdraw(address pool, address account, uint amount) 
    internal 
  {
    bool foundPool = false;

    for (uint i; i < poolsLength; i++) {
      if (pools[i] == pool) {
        foundPool = true;
        break;
      }
    }

    require(foundPool, "Pool doesn't exist");

    IReservePool(pool).withdraw(account, amount);
  }

  function _setSingleAssetPool(address _pool) 
    internal 
  {
    require(_pool != address(0), "Invalid single asset pool");
    singleAssetPool = _pool;
  }

  /** RESTRICTED FUNCTIONS */

  function addPool(address _pool, bool _isSingleAsset) 
    external 
    onlyOwner 
  {
    bool foundPool;

    for (uint i; i < poolsLength; i++) {
      if (pools[i] == _pool) {
        foundPool = true;
        break;
      }
    }

    require(!foundPool, "Pool already exists");
    pools.push(_pool);
    poolsLength++;

    if (_isSingleAsset) _setSingleAssetPool(_pool);
  }

  function removePool(address _pool) 
    external 
    onlyOwner
  {
    for (uint i; i < poolsLength; i++) {
      if (pools[i] == _pool) {
        pools[i] = pools[pools.length - 1];
        pools.pop();
        poolsLength--;
        break;
      }
    }
  }

  function enableDeposits()
    external
    onlyOwner
  {
    _unpause();
  }

  function disableDeposits()
    external
    onlyOwner
  {
    _pause();
  }

  function setSingleAssetPool(address _pool) 
    external 
    onlyOwner 
  {
    _setSingleAssetPool(_pool);
  }

  function recoverTokens(address _token) 
    external 
    onlyOwner 
  {
    IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
  }
}
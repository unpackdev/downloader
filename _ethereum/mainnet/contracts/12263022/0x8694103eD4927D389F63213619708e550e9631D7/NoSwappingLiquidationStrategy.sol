// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import "./PermissionAdmin.sol";
import "./PermissionOperators.sol";
import "./IERC20Ext.sol";
import "./IPool.sol";
import "./INoSwappingLiquidationStrategy.sol";

/// @dev The simplest liquidation strategy which requests funds from TreasuryPool and
/// 	transfer directly to treasury pool, no actual liquidation happens
contract NoSwappingLiquidationStrategy is PermissionAdmin, PermissionOperators,
	INoSwappingLiquidationStrategy {

  IPool private _treasuryPool;
  address payable private _rewardPool;

  constructor(
    address admin,
    address treasuryPoolAddress,
    address payable rewardPoolAddress
  ) PermissionAdmin(admin) {
    _setTreasuryPool(treasuryPoolAddress);
    _setRewardPool(rewardPoolAddress);
  }

  function updateTreasuryPool(address pool) external override onlyAdmin {
    _setTreasuryPool(pool);
  }

  function updateRewardPool(address payable pool) external override onlyAdmin {
    _setRewardPool(pool);
  }

  /** @dev Fast forward tokens from fee pool to treasury pool
  * @param sources list of source tokens to liquidate
  * @param amounts list of amounts corresponding to each source token
  */
  function liquidate(IERC20Ext[] calldata sources, uint256[] calldata amounts)
		external override
	{
		// check for sources and amounts length will be done in fee pool
		_treasuryPool.withdrawFunds(sources, amounts, _rewardPool);
		emit Liquidated(msg.sender, sources, amounts);
	}

  function treasuryPool() external override view returns (address) {
    return address(_treasuryPool);
  }

  function rewardPool() external override view returns (address) {
    return _rewardPool;
  }

  function _setTreasuryPool(address _pool) internal {
    require(_pool != address(0), 'invalid treasury pool');
    _treasuryPool = IPool(_pool);
    emit TreasuryPoolSet(_pool);
  }

  function _setRewardPool(address payable _pool) internal {
    require(_pool != address(0), 'invalid reward pool');
    _rewardPool = _pool;
    emit RewardPoolSet(_pool);
  }
}

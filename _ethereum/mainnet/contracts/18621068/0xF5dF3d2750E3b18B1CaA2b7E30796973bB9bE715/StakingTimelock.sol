// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Timelock.sol";
import "./IMigratable.sol";
import "./ISlashable.sol";
import "./StakingPoolBase.sol";
import "./CommunityStakingPool.sol";
import "./PriceFeedAlertsController.sol";

/// @notice This contract is the contract manager of all staking contracts. Any contract upgrades or
/// parameter
/// updates will need to be scheduled here and go through the timelock.
/// @dev The deployer will transfer the staking contracts ownership to this contract and proposer
/// will schedule an accepting transaction in the timelock. After the timelock is passed, the
/// executor can execute the transaction and the staking contracts will be owned by this contract.
/// Example operations can be found in the integration tests.
contract StakingTimelock is Timelock {
  /// @notice This error is thrown whenever a zero-address is supplied when
  /// a non-zero address is required
  error InvalidZeroAddress();

  /// @notice This struct defines the params required by the StakingTimelock contract's
  /// constructor.
  struct ConstructorParams {
    /// @notice The reward vault address
    address rewardVault;
    /// @notice The Community Staker Staking Pool
    address communityStakingPool;
    /// @notice The Operator Staking Pool
    address operatorStakingPool;
    /// @notice The PriceFeedAlertsController address
    address alertsController;
    /// @notice initial minimum delay for operations
    uint256 minDelay;
    /// @notice initial delay for operations that need buffer time in addition to the unbonding
    /// period
    uint256 delayForBufferedOps;
    /// @notice account to be granted admin role
    address admin;
    /// @notice accounts to be granted proposer role
    address[] proposers;
    /// @notice accounts to be granted executor role
    address[] executors;
    /// @notice accounts to be granted canceller role
    address[] cancellers;
  }

  constructor(ConstructorParams memory params)
    Timelock(params.minDelay, params.admin, params.proposers, params.executors, params.cancellers)
  {
    if (params.rewardVault == address(0)) revert InvalidZeroAddress();
    if (params.communityStakingPool == address(0)) revert InvalidZeroAddress();
    if (params.operatorStakingPool == address(0)) revert InvalidZeroAddress();
    if (params.alertsController == address(0)) revert InvalidZeroAddress();

    // Changing timelock delay
    _setDelay({
      target: address(this),
      selector: bytes4(keccak256("updateDelay(uint256)")),
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: address(this),
      selector: bytes4(keccak256("updateDelay((address,bytes4,uint256)[])")),
      newDelay: params.delayForBufferedOps
    });

    // Granting roles
    _setDelay({
      target: address(this),
      selector: bytes4(keccak256("grantRole(bytes32,address)")),
      newDelay: params.delayForBufferedOps
    });

    // Migrating staking pools to a new reward vault
    _setDelay({
      target: params.communityStakingPool,
      selector: StakingPoolBase.setRewardVault.selector,
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: StakingPoolBase.setRewardVault.selector,
      newDelay: params.delayForBufferedOps
    });

    // Migrating operator staking pool
    _setDelay({
      target: params.communityStakingPool,
      selector: CommunityStakingPool.setOperatorStakingPool.selector,
      newDelay: params.delayForBufferedOps
    });

    // Migrating the staking pools to the upgraded pools
    _setDelay({
      target: params.communityStakingPool,
      selector: IMigratable.setMigrationTarget.selector,
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: IMigratable.setMigrationTarget.selector,
      newDelay: params.delayForBufferedOps
    });

    // Migrating the alerts controller to the upgraded alerts controller
    _setDelay({
      target: params.alertsController,
      selector: IMigratable.setMigrationTarget.selector,
      newDelay: params.delayForBufferedOps
    });

    // Granting a new slasher role / adding a new slashing condition
    _setDelay({
      target: params.operatorStakingPool,
      selector: ISlashable.addSlasher.selector,
      newDelay: params.delayForBufferedOps
    });

    // Updating slashing configs
    _setDelay({
      target: params.operatorStakingPool,
      selector: ISlashable.setSlasherConfig.selector,
      newDelay: params.delayForBufferedOps
    });

    // Changing feed configs in the alerts controller
    _setDelay({
      target: params.alertsController,
      selector: PriceFeedAlertsController.setFeedConfigs.selector,
      newDelay: params.delayForBufferedOps
    });

    // Updating unbonding periods in the staking pools
    _setDelay({
      target: params.communityStakingPool,
      selector: StakingPoolBase.setUnbondingPeriod.selector,
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: StakingPoolBase.setUnbondingPeriod.selector,
      newDelay: params.delayForBufferedOps
    });

    // Updating claim periods in the staking pools
    _setDelay({
      target: params.communityStakingPool,
      selector: StakingPoolBase.setClaimPeriod.selector,
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: StakingPoolBase.setClaimPeriod.selector,
      newDelay: params.delayForBufferedOps
    });

    // Starting the DEFAULT_ADMIN_ROLE transfer
    _setDelay({
      target: params.rewardVault,
      selector: bytes4(keccak256("beginDefaultAdminTransfer(address)")),
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.communityStakingPool,
      selector: bytes4(keccak256("beginDefaultAdminTransfer(address)")),
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: bytes4(keccak256("beginDefaultAdminTransfer(address)")),
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.alertsController,
      selector: bytes4(keccak256("beginDefaultAdminTransfer(address)")),
      newDelay: params.delayForBufferedOps
    });

    // Setting the migration proxy address in the staking pools
    _setDelay({
      target: params.communityStakingPool,
      selector: StakingPoolBase.setMigrationProxy.selector,
      newDelay: params.delayForBufferedOps
    });
    _setDelay({
      target: params.operatorStakingPool,
      selector: StakingPoolBase.setMigrationProxy.selector,
      newDelay: params.delayForBufferedOps
    });
  }
}

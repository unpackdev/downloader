// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IERC20.sol";
import "./SafeCast.sol";
import "./SafeERC20.sol";
import "./ITransparentUpgradeableProxy.sol";
import "./IProxyAdmin.sol";
import "./AaveV2Ethereum.sol";
import "./AaveV2EthereumAMM.sol";
import "./AaveV3Ethereum.sol";
import "./MiscEthereum.sol";
import "./AaveGovernanceV2.sol";
import "./GovernanceV3Ethereum.sol";
import "./AaveSafetyModule.sol";
import "./IStakedToken.sol";
import "./IExecutor.sol";
import "./IExecutor.sol";
import "./IWrappedTokenGateway.sol";
import "./IBalancerOwnable.sol";
import "./ILendingPoolAddressProviderV1.sol";
import "./IGhoAccessControl.sol";
import "./IAaveCLRobotOperator.sol";
import "./MigratorLib.sol";

/**
 * @title EthShortMovePermissionsPayload
 * @notice Migrate permissions for Aave V1, V2, V2 AMM and V3 pools on Ethereum from governance v2 to v2.5.
 * Migrate GHO permissions to the new executors, fund cross chain controller and fund execution robot.
 * @author BGD Labs
 **/
contract EthShortMovePermissionsPayload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  address payable public constant GOVERNANCE_25_IMPL =
    payable(0x323F2c8E227b3F0d88B047Ed16581fc0b6B9B1d7);

  address payable public constant LEND_TO_AAVE_MIGRATOR =
    payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

  address public constant AAVE_MERKLE_DISTRIBUTOR = 0xa88c6D90eAe942291325f9ae3c66f3563B93FE10;

  address payable public constant ABPT = payable(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);

  address public constant AAVE_V1_ADDRESS_PROVIDER = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

  address public constant AAVE_V1_PRICE_PROVIDER = 0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4;

  uint256 public constant ETH_AMOUNT_CROSSCHAIN_CONTROLLER = 0.2 ether;
  uint256 public constant LINK_AMOUNT_CROSSCHAIN_CONTROLLER = 20 ether;

  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 400 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_CROSSCHAIN_CONTROLLER + LINK_AMOUNT_ROBOT_EXECUTION_CHAIN;

  uint256 public constant GOV_V2_ROBOT_ID =
    38708010855340815800266444206792387479170521527111639306025178205742164078384;

  address public constant ROBOT_OPERATOR = 0x020E452b463568f55BAc6Dc5aFC8F0B62Ea5f0f3;

  address public constant EXECUTION_CHAIN_ROBOT = 0x365d47ceD3D7Eb6a9bdB3814aA23cc06B2D33Ef8;

  function execute() external {
    // GOVERNANCE V3
    IProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)),
      GOVERNANCE_25_IMPL,
      abi.encodeWithSignature('initialize()')
    );

    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Ethereum.COLLECTOR,
      address(AaveV2Ethereum.POOL),
      AaveV2EthereumAssets.LINK_UNDERLYING,
      AaveV2EthereumAssets.LINK_A_TOKEN,
      TOTAL_LINK_AMOUNT,
      true
    );

    // CC FUNDING
    MigratorLib.fundCrosschainControllerNative(
      AaveV3Ethereum.COLLECTOR,
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      AaveV3EthereumAssets.WETH_A_TOKEN,
      ETH_AMOUNT_CROSSCHAIN_CONTROLLER,
      AaveV3Ethereum.WETH_GATEWAY
    );
    IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).transfer(
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      LINK_AMOUNT_CROSSCHAIN_CONTROLLER
    );

    // ROBOT
    migrateKeepers();

    // STK TOKENS - SET ADMIN ROLES
    migrateStkPermissions();

    // GHO
    migrateGHOPermissions();

    // V1 POOL
    migrateV1Pool();

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV2Ethereum.ORACLE,
      AaveV2Ethereum.LENDING_RATE_ORACLE,
      AaveV2Ethereum.WETH_GATEWAY,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      address(0), // swap collateral adapter owned by https://etherscan.io/address/0x36fedc70fec3b77caaf50e6c524fd7e5dfbd629a#code
      address(0), // repay with collateral adapter owned by https://etherscan.io/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      AaveV2Ethereum.DEBT_SWAP_ADAPTER
    );
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER,
      AaveV2EthereumAMM.ORACLE,
      AaveV2EthereumAMM.LENDING_RATE_ORACLE,
      AaveV2EthereumAMM.WETH_GATEWAY,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER_REGISTRY,
      address(0),
      address(0),
      address(0)
    );

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV3Ethereum.ACL_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV3Ethereum.EMISSION_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Ethereum.COLLECTOR,
      MiscEthereum.PROXY_ADMIN,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Ethereum.WITHDRAW_SWAP_ADAPTER,
      AaveV3Ethereum.DEBT_SWAP_ADAPTER
    );

    // MISC ECOSYSTEM

    // MerkleDistributor
    IOwnable(AAVE_MERKLE_DISTRIBUTOR).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // LendToAave Migrator
    ITransparentUpgradeableProxy(LEND_TO_AAVE_MIGRATOR).changeAdmin(MiscEthereum.PROXY_ADMIN);

    // Safety module
    ITransparentUpgradeableProxy(ABPT).changeAdmin(MiscEthereum.PROXY_ADMIN);
    IBalancerOwnable(ABPT).setController(MiscEthereum.PROXY_ADMIN);

    // Swapper
    IOwnable(MiscEthereum.AAVE_SWAPPER).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // Polygon eth bridge
    IOwnable(MiscEthereum.AAVE_POL_ETH_BRIDGE).transferOwnership(
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );

    // EXECUTOR PERMISSIONS
    // admin will be accepted on the v3 activation
    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_1));

    // new executor - change owner to payload controller
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_1).transferOwnership(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );
  }

  function migrateStkPermissions() internal {
    IStakedToken stkAave = IStakedToken(AaveSafetyModule.STK_AAVE);
    IStakedToken stkABPT = IStakedToken(AaveSafetyModule.STK_ABPT);

    stkAave.setPendingAdmin(stkAave.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    stkABPT.setPendingAdmin(stkABPT.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.CLAIM_HELPER_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.CLAIM_HELPER_ROLE()),
      false
    );
  }

  function migrateV1Pool() internal {
    // lending pool manager
    ILendingPoolAddressProviderV1(AAVE_V1_ADDRESS_PROVIDER).setLendingPoolManager(
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );

    // owner of address provider
    IOwnable(AAVE_V1_ADDRESS_PROVIDER).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // owner of price provider
    IOwnable(AAVE_V1_PRICE_PROVIDER).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }

  function migrateGHOPermissions() internal {
    IGhoAccessControl ghoToken = IGhoAccessControl(AaveV3Ethereum.GHO_TOKEN);

    ghoToken.grantRole(ghoToken.DEFAULT_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ghoToken.grantRole(ghoToken.FACILITATOR_MANAGER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ghoToken.grantRole(ghoToken.BUCKET_MANAGER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    ghoToken.renounceRole(ghoToken.DEFAULT_ADMIN_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR);
    ghoToken.renounceRole(ghoToken.FACILITATOR_MANAGER_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR);
    ghoToken.renounceRole(ghoToken.BUCKET_MANAGER_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR);
  }

  function migrateKeepers() internal {
    uint256 linkBalance = IERC20(AaveV2EthereumAssets.LINK_UNDERLYING).balanceOf(address(this));

    // REGISTER NEW EXECUTION CHAIN KEEPER
    IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).forceApprove(ROBOT_OPERATOR, linkBalance);

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5000000,
      linkBalance.toUint96()
    );

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }
}

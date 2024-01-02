// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./AaveV3.sol";
import "./AaveV2Ethereum.sol";
import "./AaveV3Ethereum.sol";
import "./AaveGovernanceV2.sol";
import "./GovernanceV3Ethereum.sol";
import "./MiscEthereum.sol";
import "./ITransparentUpgradeableProxy.sol";
import "./IProxyAdmin.sol";
import "./IExecutor.sol";
import "./IExecutor.sol";
import "./IMediator.sol";
import "./IAaveCLRobotOperator.sol";
import "./MigratorLib.sol";
import "./IGovernance.sol";

/**
 * @title EthShortV3Payload
 * @notice Execute long permissions movement, update governance contract, fund governance robots,
 * @notice upgrade aAave implementation and accept admin of the existing short executor.
 * @author BGD Labs
 **/
contract EthShortV3Payload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  address public immutable MEDIATOR;

  address public constant A_AAVE_IMPL = 0x366AE337897223AEa70e3EBe1862219386f20593;

  uint256 public constant LINK_AMOUNT_ROBOT_GOV_CHAIN = 300 ether;
  uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 100 ether;
  uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_ROBOT_GOV_CHAIN + LINK_AMOUNT_ROBOT_VOTING_CHAIN + LINK_AMOUNT_ROOTS_CONSUMER;

  uint256 public constant GOV_V2_ROBOT_ID =
    38708010855340815800266444206792387479170521527111639306025178205742164078384;

  address public constant ROBOT_OPERATOR = 0x020E452b463568f55BAc6Dc5aFC8F0B62Ea5f0f3;

  address public constant GOV_CHAIN_ROBOT = 0x011824f238AEE05329213d5Ae029e899e5412343;
  address public constant VOTING_CHAIN_ROBOT = 0x2cf0fA5b36F0f89a5EA18F835d1375974a7720B8;
  address public constant ROOTS_CONSUMER = 0x2fA6F0A65886123AFD24A575aE4554d0FCe8B577;

  address public constant GOVERNANCE_V3_IMPL = 0x58BcB647C4beFf253B4B6996c62F737B783f2cDd;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // LONG ADMIN PERMISSIONS
    IMediator(MEDIATOR).execute();

    _updateGovernance2_5();

    // update implementation and change proxy admin to long
    upgradeAAave();

    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Ethereum.COLLECTOR,
      address(AaveV2Ethereum.POOL),
      AaveV2EthereumAssets.LINK_UNDERLYING,
      AaveV2EthereumAssets.LINK_A_TOKEN,
      TOTAL_LINK_AMOUNT,
      true
    );

    // ROBOT
    migrateKeepers();

    // EXECUTOR PERMISSIONS
    // new executor - call execute payload to accept new permissions
    IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).acceptAdmin();
  }

  function _updateGovernance2_5() internal {
    IProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)),
      GOVERNANCE_V3_IMPL,
      abi.encodeWithSelector(IGovernance.initializeWithRevision.selector, 300_000)
    );

    IProxyAdmin(MiscEthereum.PROXY_ADMIN).changeProxyAdmin(
      ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)),
      MiscEthereum.PROXY_ADMIN_LONG
    );
  }

  function migrateKeepers() internal {
    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW KEEPER (GOV CHAIN, VOTING CHAIN)
    IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).forceApprove(
      ROBOT_OPERATOR,
      LINK_AMOUNT_ROBOT_GOV_CHAIN + LINK_AMOUNT_ROBOT_VOTING_CHAIN
    );

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Governance Chain Keeper',
      GOV_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_GOV_CHAIN.toUint96()
    );
    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Voting Chain Keeper',
      VOTING_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN.toUint96()
    );

    // FUND ROOTS CONSUMER
    IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).transfer(
      ROOTS_CONSUMER,
      IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).balanceOf(address(this))
    );
  }

  function upgradeAAave() internal {
    // update aAave implementation

    ConfiguratorInputTypes.UpdateATokenInput memory input = ConfiguratorInputTypes
      .UpdateATokenInput({
        asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
        treasury: address(AaveV3Ethereum.COLLECTOR),
        incentivesController: AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
        name: 'Aave Ethereum AAVE',
        symbol: 'aEthAAVE',
        implementation: A_AAVE_IMPL,
        params: bytes('') // this parameter is not actually used anywhere
      });

    AaveV3Ethereum.POOL_CONFIGURATOR.updateAToken(input);
  }
}

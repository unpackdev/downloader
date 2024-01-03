// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IProposalExecutor {
  function execute() external;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
}

interface IProxyWithAdminActions {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

interface IAaveDistributionManager {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  function configureAssets(AssetConfigInput[] calldata assetsConfigInput) external;
}

interface IAaveReserveImpl {
  function initialize(address reserveController) external;

  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

interface IControllerAaveEcosystemReserve {
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

contract UpdateSafetyModuleEmissionPayload is IProposalExecutor {
  event ProposalExecuted();

  address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  IAaveDistributionManager public constant STK_AAVE_TOKEN =
    IAaveDistributionManager(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
  IProxyWithAdminActions public constant AAVE_RESERVE_PROXY =
    IProxyWithAdminActions(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
  IControllerAaveEcosystemReserve public constant CONTROLLER_AAVE_RESERVE =
    IControllerAaveEcosystemReserve(0x1E506cbb6721B83B1549fa1558332381Ffa61A93);
  IAaveReserveImpl public constant AAVE_RESERVE_IMPL =
    IAaveReserveImpl(0xa335E2443b59d11337E9005c9AF5bC31F8000714);

  uint256 public constant NEW_ALLOWANCE = 70_000 ether;
  uint128 public constant NEW_EMISSION_PER_SECOND = 0.006365740740740741 ether;

  function execute() external override {
    bytes memory aaveReserveInitParams =
      abi.encodeWithSelector(
        AAVE_RESERVE_IMPL.initialize.selector,
        address(CONTROLLER_AAVE_RESERVE)
      );
    AAVE_RESERVE_PROXY.upgradeToAndCall(address(AAVE_RESERVE_IMPL), aaveReserveInitParams);
    CONTROLLER_AAVE_RESERVE.approve(IERC20(AAVE_TOKEN), address(STK_AAVE_TOKEN), NEW_ALLOWANCE);

    IAaveDistributionManager.AssetConfigInput[] memory config =
      new IAaveDistributionManager.AssetConfigInput[](1);
    config[0] = IAaveDistributionManager.AssetConfigInput({
      emissionPerSecond: NEW_EMISSION_PER_SECOND,
      totalStaked: IERC20(address(STK_AAVE_TOKEN)).totalSupply(),
      underlyingAsset: address(STK_AAVE_TOKEN)
    });

    STK_AAVE_TOKEN.configureAssets(config);

    emit ProposalExecuted();
  }
}
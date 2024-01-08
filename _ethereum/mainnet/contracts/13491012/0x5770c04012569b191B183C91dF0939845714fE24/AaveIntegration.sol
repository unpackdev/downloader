// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./IIntegration.sol";
import "./IIntegrationMap.sol";
import "./IAaveLendingPool.sol";
import "./ModuleMapConsumer.sol";

/// @notice Integrates 0x Nodes to the Aave lending pool
/// @notice The Kernel contract should be added as the controller
contract AaveIntegration is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IIntegration
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  address private lendingPoolAddress;
  mapping(address => uint256) private balances;

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ The address of the module map contract
  /// @param lendingPoolAddress_ The address of the Aave lending pool contract
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    address lendingPoolAddress_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    lendingPoolAddress = lendingPoolAddress_;
  }

  /// @param tokenAddress The address of the deposited token
  /// @param amount The amount of the token being deposited
  function deposit(address tokenAddress, uint256 amount)
    external
    override
    onlyController
  {
    balances[tokenAddress] += amount;
  }

  /// @notice Withdraws token from the integration
  /// @param tokenAddress The address of the underlying token to withdraw
  /// @param amount The amoutn of the token to withdraw
  function withdraw(address tokenAddress, uint256 amount)
    public
    override
    onlyController
  {
    require(
      amount <= balances[tokenAddress],
      "AaveIntegration::withdraw: Withdraw amount exceeds balance"
    );

    if (
      amount > IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this))
    ) {
      try
        IAaveLendingPool(lendingPoolAddress).withdraw(
          tokenAddress,
          amount,
          address(this)
        )
      {} catch {}
    }

    if (
      amount > IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this))
    ) {
      amount = IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this));
    }

    balances[tokenAddress] -= amount;
    IERC20MetadataUpgradeable(tokenAddress).safeTransfer(
      moduleMap.getModuleAddress(Modules.Kernel),
      amount
    );
  }

  /// @notice Deploys all available tokens to Aave
  function deploy() external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
      IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
        integrationMap.getTokenAddress(tokenId)
      );
      uint256 tokenAmount = token.balanceOf(address(this));

      if (token.allowance(address(this), lendingPoolAddress) == 0) {
        token.safeApprove(lendingPoolAddress, type(uint256).max);
      }

      if (tokenAmount > 0) {
        try
          IAaveLendingPool(lendingPoolAddress).deposit(
            address(token),
            tokenAmount,
            address(this),
            0
          )
        {} catch {}
      }
    }
  }

  /// @notice Harvests all token yield from the Aave lending pool
  function harvestYield() external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
      address tokenAddress = integrationMap.getTokenAddress(tokenId);
      address aTokenAddress = getATokenAddress(tokenAddress);
      if (aTokenAddress != address(0)) {
        uint256 aTokenBalance = IERC20MetadataUpgradeable(aTokenAddress)
          .balanceOf(address(this));
        if (aTokenBalance > balances[tokenAddress]) {
          try
            IAaveLendingPool(lendingPoolAddress).withdraw(
              tokenAddress,
              aTokenBalance - balances[tokenAddress],
              address(moduleMap.getModuleAddress(Modules.YieldManager))
            )
          {} catch {}
        }
      }
    }
  }

  /// @dev This returns the total amount of the underlying token that
  /// @dev has been deposited to the integration contract
  /// @param tokenAddress The address of the deployed token
  /// @return The amount of the underlying token that can be withdrawn
  function getBalance(address tokenAddress)
    external
    view
    override
    returns (uint256)
  {
    return balances[tokenAddress];
  }

  /// @param underlyingTokenAddress The address of the underlying token
  /// @return The address of the corresponding aToken
  function getATokenAddress(address underlyingTokenAddress)
    public
    view
    returns (address)
  {
    IAaveLendingPool.ReserveData memory reserveData = IAaveLendingPool(
      lendingPoolAddress
    ).getReserveData(underlyingTokenAddress);

    return reserveData.aTokenAddress;
  }
}

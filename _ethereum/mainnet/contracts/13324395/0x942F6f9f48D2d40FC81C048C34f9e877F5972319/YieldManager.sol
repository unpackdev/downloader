// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IIntegrationMap.sol";
import "./IIntegration.sol";
import "./IEtherRewards.sol";
import "./IYieldManager.sol";
import "./IUniswapTrader.sol";
import "./ISushiSwapTrader.sol";
import "./IUserPositions.sol";
import "./IWeth9.sol";
import "./IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

/// @title Yield Manager
/// @notice Manages yield deployments, harvesting, processing, and distribution
contract YieldManager is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IYieldManager
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint256 private gasAccountTargetEthBalance;
  uint32 private biosBuyBackEthWeight;
  uint32 private treasuryEthWeight;
  uint32 private protocolFeeEthWeight;
  uint32 private rewardsEthWeight;
  uint256 private lastEthRewardsAmount;

  address payable private gasAccount;
  address payable private treasuryAccount;

  mapping(address => uint256) private processedWethByToken;

  receive() external payable {}

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ Address of the Module Map
  /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
  /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
  /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
  /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
  /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
  /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
  /// @param treasuryAccount_ The address of the system treasury account
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    uint256 gasAccountTargetEthBalance_,
    uint32 biosBuyBackEthWeight_,
    uint32 treasuryEthWeight_,
    uint32 protocolFeeEthWeight_,
    uint32 rewardsEthWeight_,
    address payable gasAccount_,
    address payable treasuryAccount_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
    biosBuyBackEthWeight = biosBuyBackEthWeight_;
    treasuryEthWeight = treasuryEthWeight_;
    protocolFeeEthWeight = protocolFeeEthWeight_;
    rewardsEthWeight = rewardsEthWeight_;
    gasAccount = gasAccount_;
    treasuryAccount = treasuryAccount_;
  }

  /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
  function updateGasAccountTargetEthBalance(uint256 gasAccountTargetEthBalance_)
    external
    override
    onlyController
  {
    gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
  }

  /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
  /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
  /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
  /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
  function updateEthDistributionWeights(
    uint32 biosBuyBackEthWeight_,
    uint32 treasuryEthWeight_,
    uint32 protocolFeeEthWeight_,
    uint32 rewardsEthWeight_
  ) external override onlyController {
    biosBuyBackEthWeight = biosBuyBackEthWeight_;
    treasuryEthWeight = treasuryEthWeight_;
    protocolFeeEthWeight = protocolFeeEthWeight_;
    rewardsEthWeight = rewardsEthWeight_;
  }

  /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
  function updateGasAccount(address payable gasAccount_)
    external
    override
    onlyController
  {
    gasAccount = gasAccount_;
  }

  /// @param treasuryAccount_ The address of the system treasury account
  function updateTreasuryAccount(address payable treasuryAccount_)
    external
    override
    onlyController
  {
    treasuryAccount = treasuryAccount_;
  }

  /// @notice Withdraws and then re-deploys tokens to integrations according to configured weights
  function rebalance() external override onlyController {
    _deploy();
  }

  /// @notice Deploys all tokens to all integrations according to configured weights
  function deploy() external override onlyController {
    _deploy();
  }

  function _deploy() internal {
    bool shouldRedeploy = _rebalance();
    if (shouldRedeploy) {
      _rebalance();
    }
  }

  function _rebalance() internal returns (bool redeploy) {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IStrategyMap strategyMap = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();
    uint256 integrationCount = integrationMap.getIntegrationAddressesLength();
    uint256 denominator = integrationMap.getReserveRatioDenominator();

    for (uint256 i = 0; i < integrationCount; i++) {
      address integration = integrationMap.getIntegrationAddress(i);
      for (uint256 j = 0; j < tokenCount; j++) {
        address token = integrationMap.getTokenAddress(j);
        uint256 numerator = integrationMap.getTokenReserveRatioNumerator(token);

        uint256 grossAmountInvested = strategyMap.getExpectedBalance(
          integration,
          token
        );

        uint256 desiredBalance = grossAmountInvested -
          _calculateReserveAmount(grossAmountInvested, numerator, denominator);

        uint256 actualBalance = IIntegration(integration).getBalance(token);

        if (desiredBalance > actualBalance) {
          // Underfunded, top up
          redeploy = true;
          uint256 shortage = desiredBalance - actualBalance;
          if (
            IERC20MetadataUpgradeable(token).balanceOf(
              moduleMap.getModuleAddress(Modules.Kernel)
            ) >= shortage
          ) {
            uint256 balanceBefore = IERC20MetadataUpgradeable(token).balanceOf(
              integration
            );
            IERC20MetadataUpgradeable(token).safeTransferFrom(
              moduleMap.getModuleAddress(Modules.Kernel),
              integration,
              shortage
            );
            uint256 balanceAfter = IERC20MetadataUpgradeable(token).balanceOf(
              integration
            );

            IIntegration(integration).deposit(
              token,
              balanceAfter - balanceBefore
            );
          }
        } else if (actualBalance > desiredBalance) {
          // Overfunded, give it a haircut
          redeploy = true;
          IIntegration(integration).withdraw(
            token,
            actualBalance - desiredBalance
          );
        }
      }
      IIntegration(integration).deploy();
    }
  }

  function _calculateReserveAmount(
    uint256 amount,
    uint256 numerator,
    uint256 denominator
  ) internal pure returns (uint256) {
    return (amount * numerator) / denominator;
  }

  /// @notice Harvests available yield from all tokens and integrations
  function harvestYield() public override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();
    uint256 integrationCount = integrationMap.getIntegrationAddressesLength();

    for (
      uint256 integrationId;
      integrationId < integrationCount;
      integrationId++
    ) {
      IIntegration(integrationMap.getIntegrationAddress(integrationId))
        .harvestYield();
    }

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
        integrationMap.getTokenAddress(tokenId)
      );

      uint256 tokenDesiredReserve = getDesiredReserveTokenBalance(
        address(token)
      );
      uint256 tokenActualReserve = getReserveTokenBalance(address(token));

      uint256 harvestedTokenAmount = token.balanceOf(address(this));

      // Check if reserves need to be replenished
      if (tokenDesiredReserve > tokenActualReserve) {
        // Need to replenish reserves
        if (tokenDesiredReserve - tokenActualReserve <= harvestedTokenAmount) {
          // Need to send portion of harvested token to Kernel to replenish reserves
          token.safeTransfer(
            moduleMap.getModuleAddress(Modules.Kernel),
            tokenDesiredReserve - tokenActualReserve
          );
        } else {
          // Need to send all of harvested token to Kernel to partially replenish reserves
          token.safeTransfer(
            moduleMap.getModuleAddress(Modules.Kernel),
            token.balanceOf(address(this))
          );
        }
      }
    }
  }

  /// @notice Swaps all harvested yield tokens for WETH
  function processYield() external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();
    IERC20MetadataUpgradeable weth = IERC20MetadataUpgradeable(
      integrationMap.getWethTokenAddress()
    );

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
        integrationMap.getTokenAddress(tokenId)
      );

      if (token.balanceOf(address(this)) > 0) {
        uint256 wethReceived;

        if (address(token) != address(weth)) {
          // If token is not WETH, need to swap it for WETH
          uint256 wethBalanceBefore = weth.balanceOf(address(this));

          // Swap token harvested yield for WETH. If trade succeeds, update accounting. Otherwise, do not update accounting
          token.safeTransfer(
            moduleMap.getModuleAddress(Modules.UniswapTrader),
            token.balanceOf(address(this))
          );

          IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader))
            .swapExactInput(
              address(token),
              address(weth),
              address(this),
              token.balanceOf(moduleMap.getModuleAddress(Modules.UniswapTrader))
            );

          wethReceived = weth.balanceOf(address(this)) - wethBalanceBefore;
        } else {
          // If token is WETH, no swap is needed
          wethReceived =
            weth.balanceOf(address(this)) -
            getProcessedWethByTokenSum();
        }

        // Update accounting
        processedWethByToken[address(token)] += wethReceived;
      }
    }
  }

  /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
  function distributeEth() external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address wethAddress = IIntegrationMap(integrationMap).getWethTokenAddress();

    // First fill up gas wallet with ETH
    ethToGasAccount();

    uint256 wethToDistribute = IERC20MetadataUpgradeable(wethAddress).balanceOf(
      address(this)
    );

    if (wethToDistribute > 0) {
      uint256 biosBuyBackWethAmount = (wethToDistribute *
        biosBuyBackEthWeight) / getEthWeightSum();
      uint256 treasuryWethAmount = (wethToDistribute * treasuryEthWeight) /
        getEthWeightSum();
      uint256 protocolFeeWethAmount = (wethToDistribute *
        protocolFeeEthWeight) / getEthWeightSum();
      uint256 rewardsWethAmount = wethToDistribute -
        biosBuyBackWethAmount -
        treasuryWethAmount -
        protocolFeeWethAmount;

      // Send WETH to SushiSwap trader for BIOS buy back
      IERC20MetadataUpgradeable(wethAddress).safeTransfer(
        moduleMap.getModuleAddress(Modules.SushiSwapTrader),
        biosBuyBackWethAmount
      );

      // Swap WETH for ETH and transfer to the treasury account
      IWeth9(wethAddress).withdraw(treasuryWethAmount);
      payable(treasuryAccount).transfer(treasuryWethAmount);

      // Send ETH to protocol fee accrual rewards (BIOS stakers)
      ethToProtocolFeeAccrual(protocolFeeWethAmount);

      // Send ETH to token rewards
      ethToRewards(rewardsWethAmount);
    }
  }

  /// @notice Distributes WETH to gas wallet
  function ethToGasAccount() private {
    address wethAddress = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    ).getWethTokenAddress();
    uint256 wethBalance = IERC20MetadataUpgradeable(wethAddress).balanceOf(
      address(this)
    );

    if (wethBalance > 0) {
      uint256 gasAccountActualEthBalance = gasAccount.balance;
      if (gasAccountActualEthBalance < gasAccountTargetEthBalance) {
        // Need to send ETH to gas account
        uint256 ethAmountToGasAccount;
        if (
          wethBalance < gasAccountTargetEthBalance - gasAccountActualEthBalance
        ) {
          // Send all of WETH to gas wallet
          ethAmountToGasAccount = wethBalance;
          IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
          gasAccount.transfer(ethAmountToGasAccount);
        } else {
          // Send portion of WETH to gas wallet
          ethAmountToGasAccount =
            gasAccountTargetEthBalance -
            gasAccountActualEthBalance;
          IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
          gasAccount.transfer(ethAmountToGasAccount);
        }
      }
    }
  }

  /// @notice Uses any WETH held in the SushiSwap trader to buy back BIOS which is sent to the Kernel
  function biosBuyBack() external override onlyController {
    if (
      IERC20MetadataUpgradeable(
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
          .getWethTokenAddress()
      ).balanceOf(moduleMap.getModuleAddress(Modules.SushiSwapTrader)) > 0
    ) {
      // Use all ETH sent to the SushiSwap trader to buy BIOS
      ISushiSwapTrader(moduleMap.getModuleAddress(Modules.SushiSwapTrader))
        .biosBuyBack();

      // Use all BIOS transferred to the Kernel to increase bios rewards
      IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
        .increaseBiosRewards();
    }
  }

  /// @notice Distributes ETH to Rewards per token
  /// @param ethRewardsAmount The amount of ETH rewards to distribute
  function ethToRewards(uint256 ethRewardsAmount) private {
    uint256 processedWethByTokenSum = getProcessedWethSum();
    require(
      processedWethByTokenSum > 0,
      "YieldManager::ethToRewards: No processed WETH to distribute"
    );

    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address wethAddress = integrationMap.getWethTokenAddress();
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address tokenAddress = integrationMap.getTokenAddress(tokenId);

      if (processedWethByToken[tokenAddress] > 0) {
        IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
          .increaseEthRewards(
            tokenAddress,
            (ethRewardsAmount * processedWethByToken[tokenAddress]) /
              processedWethByTokenSum
          );

        processedWethByToken[tokenAddress] = 0;
      }
    }

    lastEthRewardsAmount = ethRewardsAmount;

    IWeth9(wethAddress).withdraw(ethRewardsAmount);

    payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
      ethRewardsAmount
    );
  }

  /// @notice Distributes ETH to protocol fee accrual (BIOS staker rewards)
  /// @param protocolFeeEthRewardsAmount Amount of ETH to distribute to protocol fee accrual
  function ethToProtocolFeeAccrual(uint256 protocolFeeEthRewardsAmount)
    private
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address biosAddress = integrationMap.getBiosTokenAddress();
    address wethAddress = integrationMap.getWethTokenAddress();

    if (
      IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
        .getTokenTotalBalance(biosAddress) > 0
    ) {
      // BIOS has been deposited, increase Ether rewards for BIOS depositors
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .increaseEthRewards(biosAddress, protocolFeeEthRewardsAmount);

      IWeth9(wethAddress).withdraw(protocolFeeEthRewardsAmount);

      payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
        protocolFeeEthRewardsAmount
      );
    } else {
      // No BIOS has been deposited, send WETH back to Kernel as reserves
      IERC20MetadataUpgradeable(wethAddress).transfer(
        moduleMap.getModuleAddress(Modules.Kernel),
        protocolFeeEthRewardsAmount
      );
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return harvestedTokenBalance The amount of the token yield harvested held in the Kernel
  function getHarvestedTokenBalance(address tokenAddress)
    external
    view
    override
    returns (uint256 harvestedTokenBalance)
  {
    if (
      tokenAddress ==
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getWethTokenAddress()
    ) {
      harvestedTokenBalance =
        IERC20MetadataUpgradeable(tokenAddress).balanceOf(address(this)) -
        getProcessedWethSum();
    } else {
      harvestedTokenBalance = IERC20MetadataUpgradeable(tokenAddress).balanceOf(
          address(this)
        );
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The amount of the token held in the Kernel as reserves
  function getReserveTokenBalance(address tokenAddress)
    public
    view
    override
    returns (uint256)
  {
    require(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getIsTokenAdded(tokenAddress),
      "YieldManager::getReserveTokenBalance: Token not added"
    );
    return
      IERC20MetadataUpgradeable(tokenAddress).balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      );
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The desired amount of the token to hold in the Kernel as reserves
  function getDesiredReserveTokenBalance(address tokenAddress)
    public
    view
    override
    returns (uint256)
  {
    require(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getIsTokenAdded(tokenAddress),
      "YieldManager::getDesiredReserveTokenBalance: Token not added"
    );
    uint256 tokenReserveRatioNumerator = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    ).getTokenReserveRatioNumerator(tokenAddress);
    uint256 tokenTotalBalance = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    ).getTokenTotalBalance(tokenAddress);
    return
      (tokenTotalBalance * tokenReserveRatioNumerator) /
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getReserveRatioDenominator();
  }

  /// @return ethWeightSum The sum of ETH distribution weights
  function getEthWeightSum()
    public
    view
    override
    returns (uint32 ethWeightSum)
  {
    ethWeightSum =
      biosBuyBackEthWeight +
      treasuryEthWeight +
      protocolFeeEthWeight +
      rewardsEthWeight;
  }

  /// @return processedWethSum The sum of yields processed into WETH
  function getProcessedWethSum()
    public
    view
    override
    returns (uint256 processedWethSum)
  {
    uint256 tokenCount = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    ).getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address tokenAddress = IIntegrationMap(
        moduleMap.getModuleAddress(Modules.IntegrationMap)
      ).getTokenAddress(tokenId);
      processedWethSum += processedWethByToken[tokenAddress];
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return The amount of WETH received from token yield processing
  function getProcessedWethByToken(address tokenAddress)
    public
    view
    override
    returns (uint256)
  {
    return processedWethByToken[tokenAddress];
  }

  /// @return processedWethByTokenSum The sum of processed WETH
  function getProcessedWethByTokenSum()
    public
    view
    override
    returns (uint256 processedWethByTokenSum)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      processedWethByTokenSum += processedWethByToken[
        integrationMap.getTokenAddress(tokenId)
      ];
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
  function getTokenTotalIntegrationBalance(address tokenAddress)
    public
    view
    override
    returns (uint256 tokenTotalIntegrationBalance)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 integrationCount = integrationMap.getIntegrationAddressesLength();

    for (
      uint256 integrationId;
      integrationId < integrationCount;
      integrationId++
    ) {
      tokenTotalIntegrationBalance += IIntegration(
        integrationMap.getIntegrationAddress(integrationId)
      ).getBalance(tokenAddress);
    }
  }

  /// @return The address of the gas account
  function getGasAccount() public view override returns (address) {
    return gasAccount;
  }

  /// @return The address of the treasury account
  function getTreasuryAccount() public view override returns (address) {
    return treasuryAccount;
  }

  /// @return The last amount of ETH distributed to rewards
  function getLastEthRewardsAmount() public view override returns (uint256) {
    return lastEthRewardsAmount;
  }

  /// @return The target ETH balance of the gas account
  function getGasAccountTargetEthBalance()
    public
    view
    override
    returns (uint256)
  {
    return gasAccountTargetEthBalance;
  }

  /// @return The BIOS buyback ETH weight
  /// @return The Treasury ETH weight
  /// @return The Protocol fee ETH weight
  /// @return The rewards ETH weight
  function getEthDistributionWeights()
    public
    view
    override
    returns (
      uint32,
      uint32,
      uint32,
      uint32
    )
  {
    return (
      biosBuyBackEthWeight,
      treasuryEthWeight,
      protocolFeeEthWeight,
      rewardsEthWeight
    );
  }
}

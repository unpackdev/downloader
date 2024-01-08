// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IKernel.sol";
import "./IIntegrationMap.sol";
import "./IUserPositions.sol";
import "./IYieldManager.sol";
import "./IWeth9.sol";
import "./IUniswapTrader.sol";
import "./ISushiSwapTrader.sol";
import "./IStrategyMap.sol";
import "./ModuleMapConsumer.sol";

/// @title Kernel
/// @notice Allows users to deposit/withdraw erc20 tokens
/// @notice Allows a system admin to control which tokens are depositable
contract Kernel is
  Initializable,
  AccessControlEnumerableUpgradeable,
  ModuleMapConsumer,
  IKernel
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  bytes32 public constant OWNER_ROLE = keccak256("owner_role");
  bytes32 public constant MANAGER_ROLE = keccak256("manager_role");

  uint256 private lastDeployTimestamp;
  uint256 private lastHarvestYieldTimestamp;
  uint256 private lastProcessYieldTimestamp;
  uint256 private lastDistributeEthTimestamp;
  uint256 private lastLastDistributeEthTimestamp;
  uint256 private lastBiosBuyBackTimestamp;
  uint256 private initializationTimestamp;

  event Deposit(
    address indexed user,
    address[] tokens,
    uint256[] tokenAmounts,
    uint256 ethAmount
  );
  event Withdraw(
    address indexed user,
    address[] tokens,
    uint256[] tokenAmounts,
    uint256 ethAmount
  );
  event ClaimEthRewards(address indexed user, uint256 ethRewards);
  event ClaimBiosRewards(address indexed user, uint256 biosRewards);
  event WithdrawAllAndClaim(
    address indexed user,
    address[] tokens,
    bool withdrawWethAsEth,
    uint256[] tokenAmounts,
    uint256 ethWithdrawn,
    uint256 ethRewards,
    uint256 biosRewards
  );
  event TokenAdded(
    address indexed token,
    bool acceptingDeposits,
    bool acceptingWithdrawals,
    uint256 biosRewardWeight,
    uint256 reserveRatioNumerator
  );
  event TokenDepositsEnabled(address indexed token);
  event TokenDepositsDisabled(address indexed token);
  event TokenWithdrawalsEnabled(address indexed token);
  event TokenWithdrawalsDisabled(address indexed token);
  event TokenRewardWeightUpdated(
    address indexed token,
    uint256 biosRewardWeight
  );
  event TokenReserveRatioNumeratorUpdated(
    address indexed token,
    uint256 reserveRatioNumerator,
    bool rebalance
  );
  event TokenIntegrationWeightUpdated(
    address indexed token,
    address indexed integration,
    uint256 weight,
    bool rebalance
  );
  event GasAccountUpdated(address gasAccount);
  event TreasuryAccountUpdated(address treasuryAccount);
  event IntegrationAdded(address indexed contractAddress, string name);
  event SetBiosRewardsDuration(uint32 biosRewardsDuration);
  event SeedBiosRewards(uint256 biosAmount);
  event Deploy();
  event HarvestYield();
  event ProcessYield();
  event DistributeEth();
  event BiosBuyBack();
  event EthDistributionWeightsUpdated(
    uint32 biosBuyBackEthWeight,
    uint32 treasuryEthWeight,
    uint32 protocolFeeEthWeight,
    uint32 rewardsEthWeight
  );
  event GasAccountTargetEthBalanceUpdated(uint256 gasAccountTargetEthBalance);

  modifier onlyGasAccount() {
    require(
      msg.sender ==
        IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
          .getGasAccount(),
      "Caller is not gas account"
    );
    _;
  }

  receive() external payable {}

  /// @notice Initializes contract - used as a replacement for a constructor
  /// @param admin_ default administrator, a cold storage address
  /// @param owner_ single owner account, used to manage the managers
  /// @param moduleMap_ Module Map address
  function initialize(
    address admin_,
    address owner_,
    address moduleMap_
  ) external initializer {
    __ModuleMapConsumer_init(moduleMap_);
    __AccessControl_init();

    // make the "admin_" address the default admin role
    _setupRole(DEFAULT_ADMIN_ROLE, admin_);

    // make the "owner_" address the owner of the system
    _setupRole(OWNER_ROLE, owner_);

    // give the "owner_" address the manager role, too
    _setupRole(MANAGER_ROLE, owner_);

    // owners are admins of managers
    _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);

    initializationTimestamp = block.timestamp;
  }

  /// @param biosRewardsDuration The duration in seconds for a BIOS rewards period to last
  function setBiosRewardsDuration(uint32 biosRewardsDuration)
    external
    onlyRole(MANAGER_ROLE)
  {
    IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
      .setBiosRewardsDuration(biosRewardsDuration);

    emit SetBiosRewardsDuration(biosRewardsDuration);
  }

  /// @param biosAmount The amount of BIOS to add to the rewards
  function seedBiosRewards(uint256 biosAmount) external onlyRole(MANAGER_ROLE) {
    IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
      .seedBiosRewards(msg.sender, biosAmount);

    emit SeedBiosRewards(biosAmount);
  }

  /// @notice This function is used after tokens have been added, and a weight array should be included
  /// @param contractAddress The address of the integration contract
  /// @param name The name of the protocol being integrated to
  function addIntegration(address contractAddress, string memory name)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .addIntegration(contractAddress, name);

    emit IntegrationAdded(contractAddress, name);
  }

  /// @param tokenAddress The address of the ERC20 token contract
  /// @param acceptingDeposits Whether token deposits are enabled
  /// @param acceptingWithdrawals Whether token withdrawals are enabled
  /// @param biosRewardWeight Token weight for BIOS rewards
  /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
  function addToken(
    address tokenAddress,
    bool acceptingDeposits,
    bool acceptingWithdrawals,
    uint256 biosRewardWeight,
    uint256 reserveRatioNumerator
  ) external onlyRole(MANAGER_ROLE) {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .addToken(
        tokenAddress,
        acceptingDeposits,
        acceptingWithdrawals,
        biosRewardWeight,
        reserveRatioNumerator
      );

    if (
      IERC20MetadataUpgradeable(tokenAddress).allowance(
        moduleMap.getModuleAddress(Modules.Kernel),
        moduleMap.getModuleAddress(Modules.YieldManager)
      ) == 0
    ) {
      IERC20MetadataUpgradeable(tokenAddress).safeApprove(
        moduleMap.getModuleAddress(Modules.YieldManager),
        type(uint256).max
      );
    }

    if (
      IERC20MetadataUpgradeable(tokenAddress).allowance(
        moduleMap.getModuleAddress(Modules.Kernel),
        moduleMap.getModuleAddress(Modules.UserPositions)
      ) == 0
    ) {
      IERC20MetadataUpgradeable(tokenAddress).safeApprove(
        moduleMap.getModuleAddress(Modules.UserPositions),
        type(uint256).max
      );
    }

    emit TokenAdded(
      tokenAddress,
      acceptingDeposits,
      acceptingWithdrawals,
      biosRewardWeight,
      reserveRatioNumerator
    );
  }

  /// @param biosBuyBackEthWeight The relative weight of ETH to send to BIOS buy back
  /// @param treasuryEthWeight The relative weight of ETH to send to the treasury
  /// @param protocolFeeEthWeight The relative weight of ETH to send to protocol fee accrual
  /// @param rewardsEthWeight The relative weight of ETH to send to user rewards
  function updateEthDistributionWeights(
    uint32 biosBuyBackEthWeight,
    uint32 treasuryEthWeight,
    uint32 protocolFeeEthWeight,
    uint32 rewardsEthWeight
  ) external onlyRole(MANAGER_ROLE) {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .updateEthDistributionWeights(
        biosBuyBackEthWeight,
        treasuryEthWeight,
        protocolFeeEthWeight,
        rewardsEthWeight
      );

    emit EthDistributionWeightsUpdated(
      biosBuyBackEthWeight,
      treasuryEthWeight,
      protocolFeeEthWeight,
      rewardsEthWeight
    );
  }

  /// @notice Gives the UserPositions contract approval to transfer BIOS from Kernel
  function tokenApprovals() external onlyRole(MANAGER_ROLE) {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IERC20MetadataUpgradeable bios = IERC20MetadataUpgradeable(
      integrationMap.getBiosTokenAddress()
    );
    IERC20MetadataUpgradeable weth = IERC20MetadataUpgradeable(
      integrationMap.getWethTokenAddress()
    );

    if (
      bios.allowance(
        address(this),
        moduleMap.getModuleAddress(Modules.UserPositions)
      ) == 0
    ) {
      bios.safeApprove(
        moduleMap.getModuleAddress(Modules.UserPositions),
        type(uint256).max
      );
    }
    if (
      bios.allowance(
        address(this),
        moduleMap.getModuleAddress(Modules.YieldManager)
      ) == 0
    ) {
      bios.safeApprove(
        moduleMap.getModuleAddress(Modules.YieldManager),
        type(uint256).max
      );
    }

    if (
      weth.allowance(
        address(this),
        moduleMap.getModuleAddress(Modules.UserPositions)
      ) == 0
    ) {
      weth.safeApprove(
        moduleMap.getModuleAddress(Modules.UserPositions),
        type(uint256).max
      );
    }

    if (
      weth.allowance(
        address(this),
        moduleMap.getModuleAddress(Modules.YieldManager)
      ) == 0
    ) {
      weth.safeApprove(
        moduleMap.getModuleAddress(Modules.YieldManager),
        type(uint256).max
      );
    }
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function enableTokenDeposits(address tokenAddress)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .enableTokenDeposits(tokenAddress);

    emit TokenDepositsEnabled(tokenAddress);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function disableTokenDeposits(address tokenAddress)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .disableTokenDeposits(tokenAddress);

    emit TokenDepositsDisabled(tokenAddress);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function enableTokenWithdrawals(address tokenAddress)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .enableTokenWithdrawals(tokenAddress);

    emit TokenWithdrawalsEnabled(tokenAddress);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  function disableTokenWithdrawals(address tokenAddress)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .disableTokenWithdrawals(tokenAddress);

    emit TokenWithdrawalsDisabled(tokenAddress);
  }

  /// @param tokenAddress The address of the token ERC20 contract
  /// @param updatedWeight The updated token BIOS reward weight
  function updateTokenRewardWeight(address tokenAddress, uint256 updatedWeight)
    external
    onlyRole(MANAGER_ROLE)
  {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .updateTokenRewardWeight(tokenAddress, updatedWeight);

    emit TokenRewardWeightUpdated(tokenAddress, updatedWeight);
  }

  /// @param tokenAddress the address of the token ERC20 contract
  /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
  /// @param rebalance Boolean indicating whether rebalance should be triggered
  function updateTokenReserveRatioNumerator(
    address tokenAddress,
    uint256 reserveRatioNumerator,
    bool rebalance
  ) external onlyRole(MANAGER_ROLE) {
    IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
      .updateTokenReserveRatioNumerator(tokenAddress, reserveRatioNumerator);

    if (rebalance) {
      IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
        .rebalance();
    }

    emit TokenReserveRatioNumeratorUpdated(
      tokenAddress,
      reserveRatioNumerator,
      rebalance
    );
  }

  /// @param gasAccount The address of the account to send ETH to gas for executing bulk system functions
  function updateGasAccount(address payable gasAccount)
    external
    onlyRole(MANAGER_ROLE)
  {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .updateGasAccount(gasAccount);

    emit GasAccountUpdated(gasAccount);
  }

  /// @param treasuryAccount The address of the system treasury account
  function updateTreasuryAccount(address payable treasuryAccount)
    external
    onlyRole(MANAGER_ROLE)
  {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .updateTreasuryAccount(treasuryAccount);

    emit TreasuryAccountUpdated(treasuryAccount);
  }

  /// @param gasAccountTargetEthBalance The target ETH balance of the gas account
  function updateGasAccountTargetEthBalance(uint256 gasAccountTargetEthBalance)
    external
    onlyRole(MANAGER_ROLE)
  {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .updateGasAccountTargetEthBalance(gasAccountTargetEthBalance);

    emit GasAccountTargetEthBalanceUpdated(gasAccountTargetEthBalance);
  }

  /// @notice User is allowed to deposit whitelisted tokens
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  function deposit(address[] memory tokens, uint256[] memory amounts)
    external
    payable
  {
    if (msg.value > 0) {
      // Convert ETH to WETH
      address wethAddress = IIntegrationMap(
        moduleMap.getModuleAddress(Modules.IntegrationMap)
      ).getWethTokenAddress();
      IWeth9(wethAddress).deposit{ value: msg.value }();
    }

    IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions)).deposit(
      msg.sender,
      tokens,
      amounts,
      msg.value
    );

    emit Deposit(msg.sender, tokens, amounts, msg.value);
  }

  /// @notice User is allowed to withdraw tokens
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  function withdraw(
    address[] memory tokens,
    uint256[] memory amounts,
    bool withdrawWethAsEth
  ) external {
    uint256 ethWithdrawn = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    ).withdraw(msg.sender, tokens, amounts, withdrawWethAsEth);

    if (ethWithdrawn > 0) {
      IWeth9(
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
          .getWethTokenAddress()
      ).withdraw(ethWithdrawn);

      payable(msg.sender).transfer(ethWithdrawn);
    }

    emit Withdraw(msg.sender, tokens, amounts, ethWithdrawn);
  }

  /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
  /// @param tokens Array of token address that user is exiting positions from
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  /// @return tokenAmounts The amounts of each token being withdrawn
  /// @return ethWithdrawn The amount of WETH balance being withdrawn as ETH
  /// @return ethClaimed The amount of ETH being claimed from rewards
  /// @return biosClaimed The amount of BIOS being claimed from rewards
  function withdrawAllAndClaim(address[] memory tokens, bool withdrawWethAsEth)
    external
    returns (
      uint256[] memory tokenAmounts,
      uint256 ethWithdrawn,
      uint256 ethClaimed,
      uint256 biosClaimed
    )
  {
    (tokenAmounts, ethWithdrawn, ethClaimed, biosClaimed) = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    ).withdrawAllAndClaim(msg.sender, tokens, withdrawWethAsEth);

    if (ethWithdrawn > 0) {
      IWeth9(
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
          .getWethTokenAddress()
      ).withdraw(ethWithdrawn);
    }

    if (ethWithdrawn + ethClaimed > 0) {
      payable(msg.sender).transfer(ethWithdrawn + ethClaimed);
    }

    emit WithdrawAllAndClaim(
      msg.sender,
      tokens,
      withdrawWethAsEth,
      tokenAmounts,
      ethWithdrawn,
      ethClaimed,
      biosClaimed
    );
  }

  /// @notice Allows user to claim their BIOS rewards
  /// @return ethClaimed The amount of ETH claimed by the user
  function claimEthRewards() public returns (uint256 ethClaimed) {
    ethClaimed = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    ).claimEthRewards(msg.sender);

    payable(msg.sender).transfer(ethClaimed);

    emit ClaimEthRewards(msg.sender, ethClaimed);
  }

  /// @notice Allows user to claim their BIOS rewards
  /// @return biosClaimed The amount of BIOS claimed by the user
  function claimBiosRewards() public returns (uint256 biosClaimed) {
    biosClaimed = IUserPositions(
      moduleMap.getModuleAddress(Modules.UserPositions)
    ).claimBiosRewards(msg.sender);

    emit ClaimBiosRewards(msg.sender, biosClaimed);
  }

  /// @notice Allows user to claim their ETH and BIOS rewards
  /// @return ethClaimed The amount of ETH claimed by the user
  /// @return biosClaimed The amount of BIOS claimed by the user
  function claimAllRewards()
    external
    returns (uint256 ethClaimed, uint256 biosClaimed)
  {
    ethClaimed = claimEthRewards();
    biosClaimed = claimBiosRewards();
  }

  /// @notice Deploys all tokens to all integrations according to configured weights
  function deploy() external onlyGasAccount {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager)).deploy();
    lastDeployTimestamp = block.timestamp;
    emit Deploy();
  }

  /// @notice Harvests available yield from all tokens and integrations
  function harvestYield() external onlyGasAccount {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .harvestYield();
    lastHarvestYieldTimestamp = block.timestamp;
    emit HarvestYield();
  }

  /// @notice Swaps all harvested yield tokens for WETH
  function processYield() external onlyGasAccount {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .processYield();
    lastProcessYieldTimestamp = block.timestamp;
    emit ProcessYield();
  }

  /// @notice Distributes WETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
  function distributeEth() external onlyGasAccount {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .distributeEth();
    lastLastDistributeEthTimestamp = lastDistributeEthTimestamp;
    lastDistributeEthTimestamp = block.timestamp;
    emit DistributeEth();
  }

  /// @notice Uses any WETH held in the SushiSwap integration to buy back BIOS which is sent to the Kernel
  function biosBuyBack() external onlyGasAccount {
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager))
      .biosBuyBack();
    lastBiosBuyBackTimestamp = block.timestamp;
    emit BiosBuyBack();
  }

  /// @param account The address of the account to check if they are a manager
  /// @return Bool indicating whether the account is a manger
  function isManager(address account) public view override returns (bool) {
    return hasRole(MANAGER_ROLE, account);
  }

  /// @param account The address of the account to check if they are an owner
  /// @return Bool indicating whether the account is an owner
  function isOwner(address account) public view override returns (bool) {
    return hasRole(OWNER_ROLE, account);
  }

  /// @return The timestamp the deploy function was last called
  function getLastDeployTimestamp() external view returns (uint256) {
    return lastDeployTimestamp;
  }

  /// @return The timestamp the harvestYield function was last called
  function getLastHarvestYieldTimestamp() external view returns (uint256) {
    return lastHarvestYieldTimestamp;
  }

  /// @return The timestamp the processYield function was last called
  function getLastProcessYieldTimestamp() external view returns (uint256) {
    return lastProcessYieldTimestamp;
  }

  /// @return The timestamp the distributeEth function was last called
  function getLastDistributeEthTimestamp() external view returns (uint256) {
    return lastDistributeEthTimestamp;
  }

  /// @return The timestamp the biosBuyBack function was last called
  function getLastBiosBuyBackTimestamp() external view returns (uint256) {
    return lastBiosBuyBackTimestamp;
  }

  /// @return ethRewardsTimePeriod The number of seconds between the last two ETH payouts
  function getEthRewardsTimePeriod()
    external
    view
    returns (uint256 ethRewardsTimePeriod)
  {
    if (lastDistributeEthTimestamp > 0) {
      if (lastLastDistributeEthTimestamp > 0) {
        ethRewardsTimePeriod =
          lastDistributeEthTimestamp -
          lastLastDistributeEthTimestamp;
      } else {
        ethRewardsTimePeriod =
          lastDistributeEthTimestamp -
          initializationTimestamp;
      }
    } else {
      ethRewardsTimePeriod = 0;
    }
  }

  /// @notice User can enter a strategy with the funds they have on deposit
  /// @param strategyID  The strategy to deposit the tokens into
  /// @param tokens  the tokens to be enter the strategy with
  /// @param amounts  the amount of tokens to use
  function enterStrategy(
    uint256 strategyID,
    address[] memory tokens,
    uint256[] memory amounts
  ) external {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap)).enterStrategy(
        strategyID,
        msg.sender,
        tokens,
        amounts
      );
    IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
      .transferToStrategy(msg.sender, tokens, amounts);
  }

  /// @notice User can exit a strategy
  /// @param strategyID  the strategy to exit
  /// @param tokens  the tokens to withdraw
  /// @param amounts  the amounts to withdraw
  function exitStrategy(
    uint256 strategyID,
    address[] memory tokens,
    uint256[] memory amounts
  ) external {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap)).exitStrategy(
      strategyID,
      msg.sender,
      tokens,
      amounts
    );
    IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
      .transferFromStrategy(msg.sender, tokens, amounts);
  }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IIntegrationMap.sol";
import "./IBiosRewards.sol";
import "./IEtherRewards.sol";
import "./IUserPositions.sol";
import "./IWeth9.sol";
import "./IYieldManager.sol";
import "./IIntegration.sol";
import "./IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

/// @title User Positions
/// @notice Allows users to deposit/withdraw erc20 tokens
contract UserPositions is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IUserPositions
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint32 private _biosRewardsDuration;

  // Token address => total supply held by the contract
  mapping(address => uint256) private _totalSupply;

  // Token address => User address => User's balance of token held by the contract
  mapping(address => mapping(address => uint256)) private _balances;

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ Address of the Module Map
  /// @param biosRewardsDuration_ The duration is seconds for a BIOS rewards period to last
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    uint32 biosRewardsDuration_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    _biosRewardsDuration = biosRewardsDuration_;
  }

  /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
  function setBiosRewardsDuration(uint32 biosRewardsDuration_)
    external
    override
    onlyController
  {
    require(
      _biosRewardsDuration != biosRewardsDuration_,
      "UserPositions::setBiosRewardsDuration: Duration must be set to a new value"
    );
    require(
      biosRewardsDuration_ > 0,
      "UserPositions::setBiosRewardsDuration: Duration must be greater than zero"
    );

    _biosRewardsDuration = biosRewardsDuration_;
  }

  /// @param sender The account seeding BIOS rewards
  /// @param biosAmount The amount of BIOS to add to rewards
  function seedBiosRewards(address sender, uint256 biosAmount)
    external
    override
    onlyController
  {
    require(
      biosAmount > 0,
      "UserPositions::seedBiosRewards: BIOS amount must be greater than zero"
    );

    IERC20MetadataUpgradeable bios = IERC20MetadataUpgradeable(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getBiosTokenAddress()
    );

    bios.safeTransferFrom(
      sender,
      moduleMap.getModuleAddress(Modules.Kernel),
      biosAmount
    );

    _increaseBiosRewards();
  }

  /// @notice User is allowed to deposit whitelisted tokens
  /// @param depositor Address of the account depositing
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  /// @param ethAmount The amount of ETH sent with the deposit
  function deposit(
    address depositor,
    address[] memory tokens,
    uint256[] memory amounts,
    uint256 ethAmount
  ) external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      // Token must be accepting deposits
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[tokenId]),
        "UserPositions::deposit: This token is not accepting deposits"
      );

      require(
        amounts[tokenId] > 0,
        "UserPositions::deposit: Deposit amount must be greater than zero"
      );

      IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(
        tokens[tokenId]
      );

      // Get the balance before the transfer
      uint256 beforeBalance = erc20.balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      );

      // Transfer the tokens from the depositor to the Kernel
      erc20.safeTransferFrom(
        depositor,
        moduleMap.getModuleAddress(Modules.Kernel),
        amounts[tokenId]
      );

      // Get the balance after the transfer
      uint256 afterBalance = erc20.balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      );
      uint256 actualAmount = afterBalance - beforeBalance;

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(tokens[tokenId], depositor, actualAmount);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], depositor);

      // Update balances
      _totalSupply[tokens[tokenId]] += actualAmount;
      _balances[tokens[tokenId]][depositor] += actualAmount;
    }

    if (ethAmount > 0) {
      address wethAddress = integrationMap.getWethTokenAddress();

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(wethAddress, depositor, ethAmount);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(wethAddress, depositor);

      // Update WETH balances
      _totalSupply[wethAddress] += ethAmount;
      _balances[wethAddress][depositor] += ethAmount;
    }
  }

  /// @notice User is allowed to withdraw tokens
  /// @param recipient The address of the user withdrawing
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  function withdraw(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bool withdrawWethAsEth
  ) external override onlyController returns (uint256 ethWithdrawn) {
    ethWithdrawn = _withdraw(recipient, tokens, amounts, withdrawWethAsEth);
  }

  /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
  /// @param recipient The address of the user withdrawing tokens
  /// @param tokens Array of token address that user is exiting positions from
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  /// @return tokenAmounts The amounts of each token being withdrawn
  /// @return ethWithdrawn The amount of ETH being withdrawn
  /// @return ethClaimed The amount of ETH being claimed from rewards
  /// @return biosClaimed The amount of BIOS being claimed from rewards
  function withdrawAllAndClaim(
    address recipient,
    address[] memory tokens,
    bool withdrawWethAsEth
  )
    external
    override
    onlyController
    returns (
      uint256[] memory tokenAmounts,
      uint256 ethWithdrawn,
      uint256 ethClaimed,
      uint256 biosClaimed
    )
  {
    tokenAmounts = new uint256[](tokens.length);

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      tokenAmounts[tokenId] = userTokenBalance(tokens[tokenId], recipient);
    }

    ethWithdrawn = _withdraw(
      recipient,
      tokens,
      tokenAmounts,
      withdrawWethAsEth
    );

    if (
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .getUserEthRewards(recipient) > 0
    ) {
      ethClaimed = _claimEthRewards(recipient);
    }

    biosClaimed = _claimBiosRewards(recipient);
  }

  /// @notice User is allowed to withdraw tokens
  /// @param recipient The address of the user withdrawing
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  function _withdraw(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bool withdrawWethAsEth
  ) private returns (uint256 ethWithdrawn) {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address wethAddress = integrationMap.getWethTokenAddress();

    require(
      tokens.length == amounts.length,
      "UserPositions::_withdraw: Tokens array length does not match amounts array length"
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      require(
        amounts[tokenId] > 0,
        "UserPositions::_withdraw: Withdraw amount must be greater than zero"
      );
      require(
        integrationMap.getTokenAcceptingWithdrawals(tokens[tokenId]),
        "UserPositions::_withdraw: This token is not accepting withdrawals"
      );
      require(
        amounts[tokenId] <= _balances[tokens[tokenId]][recipient],
        "UserPositions::_withdraw: Withdraw amount exceeds user balance"
      );

      if (
        IERC20MetadataUpgradeable(tokens[tokenId]).balanceOf(
          moduleMap.getModuleAddress(Modules.Kernel)
        ) < amounts[tokenId]
      ) {
        // Token reserve balance in Kernel is not enough to support to withdrawal, need to close integration positions
        closePositionsForWithdrawal(tokens[tokenId], amounts[tokenId]);

        if (
          IERC20MetadataUpgradeable(tokens[tokenId]).balanceOf(
            moduleMap.getModuleAddress(Modules.Kernel)
          ) < amounts[tokenId]
        ) {
          // If token reserve balance is still not enough, adjust the token amount
          amounts[tokenId] = IERC20MetadataUpgradeable(tokens[tokenId])
            .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
        }
      }

      if (tokens[tokenId] == wethAddress && withdrawWethAsEth) {
        ethWithdrawn = amounts[tokenId];
      } else {
        // Send the tokens back to specified recipient
        IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
          moduleMap.getModuleAddress(Modules.Kernel),
          recipient,
          amounts[tokenId]
        );
      }

      // Decrease rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .decreaseRewards(tokens[tokenId], recipient, amounts[tokenId]);

      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] -= amounts[tokenId];
      _balances[tokens[tokenId]][recipient] -= amounts[tokenId];
    }
  }

  /// @param token The address of the token to withdraw from integrations
  /// @param amount The token amount needed in the Kernel for withdrawal
  function closePositionsForWithdrawal(address token, uint256 amount) private {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IStrategyMap strategyMap = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    );

    uint256 integrationWeightSum = strategyMap.getIntegrationWeightSum();

    // Iterate through integrations and close positions in proportion to integration weights
    for (
      uint256 integrationId;
      integrationId < integrationMap.getIntegrationAddressesLength();
      integrationId++
    ) {
      address integrationAddress = integrationMap.getIntegrationAddress(
        integrationId
      );
      uint256 desiredWithdrawAmount = (amount *
        strategyMap.getIntegrationWeight(integrationAddress)) /
        integrationWeightSum;

      if (
        desiredWithdrawAmount >
        IIntegration(integrationAddress).getBalance(token)
      ) {
        desiredWithdrawAmount = IIntegration(integrationAddress).getBalance(
          token
        );
      }

      IIntegration(integrationAddress).withdraw(token, desiredWithdrawAmount);
    }

    if (
      IERC20MetadataUpgradeable(token).balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      ) < amount
    ) {
      // Amount in Kernel is still not enough, start fully closing integration positions until amount is satisfied
      fullyClosePositionsForWithdrawal(token, amount);
    }
  }

  /// @notice Fully closes the specified token positions in each integration until the desired balance
  /// @notice in the Kernel is satisfied, or all positions have been closed
  function fullyClosePositionsForWithdrawal(address token, uint256 amount)
    private
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 integrationId;
    bool doneClosingPositions;

    while (!doneClosingPositions) {
      IIntegration integration = IIntegration(
        integrationMap.getIntegrationAddress(integrationId)
      );

      // Withdraw the tokens full balance from the integration
      integration.withdraw(token, integration.getBalance(token));

      if (
        integrationId == integrationMap.getIntegrationAddressesLength() - 1 ||
        IERC20MetadataUpgradeable(token).balanceOf(
          moduleMap.getModuleAddress(Modules.Kernel)
        ) >=
        amount
      ) {
        // If the last integration has been reached, or the desired Kernel amount has been satisfied,
        // Then stop closing positions
        doneClosingPositions = true;
      }

      integrationId++;
    }
  }

  /**
    @notice Moves funds from a user's position to a strategy
    @param recipient The user to move the funds from
    @param tokens The tokens to be moved
    @param amounts The amounts to be moved
     */
  function transferToStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external override onlyController {
    require(
      tokens.length == amounts.length,
      "UserPositions::_withdraw: Tokens array length does not match amounts array length"
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      require(
        amounts[tokenId] > 0,
        "UserPositions::_withdraw: Withdraw amount must be greater than zero"
      );
      require(
        amounts[tokenId] <= _balances[tokens[tokenId]][recipient],
        "UserPositions::_withdraw: Withdraw amount exceeds user balance"
      );

      // Decrease rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .decreaseRewards(tokens[tokenId], recipient, amounts[tokenId]);

      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] -= amounts[tokenId];
      _balances[tokens[tokenId]][recipient] -= amounts[tokenId];
    }
  }

  /**
    @notice Updates a user's position with funds moved from a strategy
    @param recipient The user to move the funds to
    @param tokens The tokens to be moved
    @param amounts The amounts to be moved
     */
  function transferFromStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      // Token must be accepting deposits
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[tokenId]),
        "UserPositions::deposit: This token is not accepting deposits"
      );
      require(
        amounts[tokenId] > 0,
        "UserPositions::deposit: Deposit amount must be greater than zero"
      );

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(tokens[tokenId], recipient, amounts[tokenId]);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] += amounts[tokenId];
      _balances[tokens[tokenId]][recipient] += amounts[tokenId];
    }
  }

  /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
  function increaseBiosRewards() external override onlyController {
    _increaseBiosRewards();
  }

  /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
  function _increaseBiosRewards() private {
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address biosAddress = integrationMap.getBiosTokenAddress();
    uint256 kernelBiosBalance = IERC20MetadataUpgradeable(biosAddress)
      .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));

    require(
      kernelBiosBalance >
        biosRewards.getBiosRewards() + _totalSupply[biosAddress],
      "UserPositions::increaseBiosRewards: No available BIOS to add to rewards"
    );

    uint256 availableBiosRewards = kernelBiosBalance -
      biosRewards.getBiosRewards() -
      _totalSupply[biosAddress];

    uint256 tokenCount = integrationMap.getTokenAddressesLength();
    uint256 biosRewardWeightSum = integrationMap.getBiosRewardWeightSum();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = integrationMap.getTokenAddress(tokenId);
      uint256 tokenBiosRewardWeight = integrationMap.getTokenBiosRewardWeight(
        token
      );
      uint256 tokenBiosRewardAmount = (availableBiosRewards *
        tokenBiosRewardWeight) / biosRewardWeightSum;
      _increaseTokenBiosRewards(token, tokenBiosRewardAmount);
    }
  }

  /// @param token The address of the ERC20 token contract
  /// @param biosReward The added reward amount
  function _increaseTokenBiosRewards(address token, uint256 biosReward)
    private
  {
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );

    require(
      IERC20MetadataUpgradeable(
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
          .getBiosTokenAddress()
      ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel)) >=
        biosReward + biosRewards.getBiosRewards(),
      "UserPositions::increaseTokenBiosRewards: Not enough available BIOS for specified amount"
    );

    biosRewards.notifyRewardAmount(token, biosReward, _biosRewardsDuration);
  }

  /// @param recipient The address of the user claiming BIOS rewards
  function claimEthRewards(address recipient)
    external
    override
    onlyController
    returns (uint256 ethClaimed)
  {
    ethClaimed = _claimEthRewards(recipient);
  }

  /// @param recipient The address of the user claiming BIOS rewards
  function _claimEthRewards(address recipient)
    private
    returns (uint256 ethClaimed)
  {
    ethClaimed = IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
      .claimEthRewards(recipient);
  }

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the user claiming BIOS rewards
  function claimBiosRewards(address recipient)
    external
    override
    onlyController
    returns (uint256 biosClaimed)
  {
    biosClaimed = _claimBiosRewards(recipient);
  }

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the user claiming BIOS rewards
  function _claimBiosRewards(address recipient)
    private
    returns (uint256 biosClaimed)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );

    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = integrationMap.getTokenAddress(tokenId);

      if (biosRewards.earned(token, recipient) > 0) {
        biosClaimed += IBiosRewards(
          moduleMap.getModuleAddress(Modules.BiosRewards)
        ).claimReward(token, recipient);
      }
    }

    IERC20MetadataUpgradeable(integrationMap.getBiosTokenAddress())
      .safeTransferFrom(
        moduleMap.getModuleAddress(Modules.Kernel),
        recipient,
        biosClaimed
      );
  }

  /// @param asset Address of the ERC20 token contract
  /// @return The total balance of the asset deposited in the system
  function totalTokenBalance(address asset)
    public
    view
    override
    returns (uint256)
  {
    return _totalSupply[asset];
  }

  /// @param asset Address of the ERC20 token contract
  /// @param account Address of the user account
  function userTokenBalance(address asset, address account)
    public
    view
    override
    returns (uint256)
  {
    return _balances[asset][account];
  }

  /// @return The Bios Rewards Duration
  function getBiosRewardsDuration() public view override returns (uint32) {
    return _biosRewardsDuration;
  }
}

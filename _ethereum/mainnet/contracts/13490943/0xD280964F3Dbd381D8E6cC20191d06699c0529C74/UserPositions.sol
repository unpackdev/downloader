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
import "./IAMMIntegration.sol";
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

  // Token address => User address => Balance of tokens a user has deposited
  mapping(address => mapping(address => uint256)) private _balances;

  // Token => User => balance of tokens that still reside in an integration, but that are eligible to be withdrawn by a user
  mapping(address => mapping(address => uint256)) private _virtualBalances;

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

      // Process user withdrawal amount management, and close out positions as needed to fund the withdrawal
      uint256 reserveBalance = IERC20MetadataUpgradeable(tokens[tokenId])
        .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));

      _handleWithdrawal(
        recipient,
        tokens[tokenId],
        reserveBalance < amounts[tokenId]
          ? amounts[tokenId] - reserveBalance
          : amounts[tokenId],
        reserveBalance < amounts[tokenId]
      );

      if (tokens[tokenId] == wethAddress && withdrawWethAsEth) {
        ethWithdrawn = amounts[tokenId];
      } else {
        uint256 currentReserves = IERC20MetadataUpgradeable(tokens[tokenId])
          .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
        if (currentReserves < amounts[tokenId]) {
          // Amounts recovered from the integrations for the user was lower than requested, likely due to fees (see yearn).
          IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
            moduleMap.getModuleAddress(Modules.Kernel),
            recipient,
            currentReserves
          );
        } else {
          // Send the tokens back to specified recipient
          IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
            moduleMap.getModuleAddress(Modules.Kernel),
            recipient,
            amounts[tokenId]
          );
        }
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

  /**
    @notice Processes updates to user's withdrawal amounts. Will close out positions to fund the withdrawal if requested
    @param user  The user requesting withdrawal
    @param token  the token to withdraw
    @param amount  The amount to withdraw 
    @param shouldClosePositions  If the reserves aren't enough to cover the withdrawal, this will trigger a gas efficient closure of the user's positions
     */
  function _handleWithdrawal(
    address user,
    address token,
    uint256 amount,
    bool shouldClosePositions
  ) internal {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IStrategyMap strategyMap = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    );
    uint256 currentAmount = amount;

    for (
      uint256 i = 0;
      i < integrationMap.getIntegrationAddressesLength();
      i++
    ) {
      address integration = integrationMap.getIntegrationAddress(i);

      uint32[] memory pools = strategyMap.getPools(integration, token);
      if (pools.length > 0) {
        for (uint256 j = 0; j < pools.length; j++) {
          uint256 allowance = strategyMap.getUserWithdrawalVector(
            user,
            token,
            integration,
            pools[j]
          );

          if (allowance > 0 && currentAmount > 0) {
            uint256 withdrawableAmount = getWithdrawableAmount(
              token,
              allowance
            );

            currentAmount -= withdrawableAmount;

            if (shouldClosePositions) {
              // Close positions, leaving deploy vector untouched
              if (pools[j] == 0) {
                IIntegration(integration).withdraw(token, withdrawableAmount);
              } else {
                IAMMIntegration(integration).withdraw(
                  token,
                  withdrawableAmount,
                  pools[j]
                );
              }
            } else {
              // Decrease deploy vector so it pulls funds to top off reserves at next deploy
              strategyMap.decreaseDeployAmountChange(
                integration,
                pools[j],
                token,
                withdrawableAmount
              );
            }
            strategyMap.updateUserWithdrawalVector(
              user,
              token,
              integration,
              pools[j],
              allowance
            );
          }
        }
      }
      if (currentAmount == 0) {
        break;
      }
    }
  }

  function getWithdrawableAmount(address token, uint256 allowance)
    private
    view
    returns (uint256)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    return
      allowance -
      ((allowance * integrationMap.getTokenReserveRatioNumerator(token)) /
        integrationMap.getReserveRatioDenominator());
  }

  function abs(int256 val) internal pure returns (uint256) {
    return uint256(val >= 0 ? val : -val);
  }

  /**
    @notice Moves funds from a user's position to a strategy
    @param recipient The user to move the funds from
    @param tokens The tokens and amounts to be moved
     */
  function transferToStrategy(
    address recipient,
    IStrategyMap.TokenMovement[] calldata tokens
  ) external override onlyController {
    for (uint256 i; i < tokens.length; i++) {
      require(
        tokens[i].amount > 0,
        "UserPositions::_withdraw: Withdraw amount must be greater than zero"
      );
      require(
        tokens[i].amount <= _balances[tokens[i].token][recipient],
        "UserPositions::_withdraw: Withdraw amount exceeds user balance"
      );

      // Decrease rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .decreaseRewards(tokens[i].token, recipient, tokens[i].amount);

      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[i].token, recipient);

      // Update balances
      _totalSupply[tokens[i].token] -= tokens[i].amount;
      _balances[tokens[i].token][recipient] -= tokens[i].amount;

      // Reduce virtual balances by transfer amount
      if (_virtualBalances[tokens[i].token][recipient] >= tokens[i].amount) {
        _virtualBalances[tokens[i].token][recipient] -= tokens[i].amount;
      } else {
        // Drop to zero, as the remaining balance is composed of real balance
        _virtualBalances[tokens[i].token][recipient] = 0;
      }
    }
  }

  /**
    @notice Updates a user's position with funds moved from a strategy
    @param recipient The user to move the funds to
    @param tokens The tokens and amounts to be moved
     */
  function transferFromStrategy(
    address recipient,
    IStrategyMap.TokenMovement[] calldata tokens
  ) external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    for (uint256 i; i < tokens.length; i++) {
      // Token must be accepting deposits
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[i].token),
        "UserPositions::deposit: This token is not accepting deposits"
      );
      require(
        tokens[i].amount > 0,
        "UserPositions::deposit: Deposit amount must be greater than zero"
      );

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(tokens[i].token, recipient, tokens[i].amount);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[i].token, recipient);

      // Update balances
      _totalSupply[tokens[i].token] += tokens[i].amount;
      _balances[tokens[i].token][recipient] += tokens[i].amount;
      _virtualBalances[tokens[i].token][recipient] += tokens[i].amount;
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

  function getUserVirtualBalance(address user, address token)
    external
    view
    override
    returns (uint256)
  {
    return _virtualBalances[token][user];
  }
}

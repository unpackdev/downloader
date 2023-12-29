//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./DefinitiveRewardToken.sol";
import "./IDefinitiveVault.sol";

/**
 * This contract is a MasterChef for Definitive single sided staking strategies.
 */
contract DefinitiveStakingManager is Ownable {
  using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure

  // Definitive variables
  DefinitiveRewardToken public rewardToken; // Token to be payed as reward
  IDefinitiveVault public definitiveVault;

  uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations
  address private constant DEFINITIVE_NATIVE_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Staking user for a strategy
  struct StrategyStaker {
    uint256 amount; // The lp tokens quantity the user has staked.
    uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
  }

  // Strategy variables
  address[] underlyingTokenAddresses;
  uint256 lpTokensStaked; // LP tokens staked in the strategy
  uint256 lastRewardedBlock = 0;
  uint256 accumulatedRewardsPerShare = 0;

  // Mapping staker address => StrategyStaker
  mapping(address => StrategyStaker) public strategyStakers;

  // Events
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event HarvestRewards(address indexed user, uint256 amount);

  // Fallback function
  receive() external payable {}

  // Constructor
  constructor(address _definitiveVaultAddress) {
    // Deploy ERC20 bookkeeping code and grant minter role to definitive vault
    rewardToken = new DefinitiveRewardToken("Definitive Reward Token", "DRT");

    // Set the variables
    definitiveVault = IDefinitiveVault(_definitiveVaultAddress);

    // Get the underlying tokens addresses from Definitive
    for (uint8 i = 0; i < definitiveVault.LP_UNDERLYING_TOKENS_COUNT(); i++) {
      underlyingTokenAddresses.push(definitiveVault.LP_UNDERLYING_TOKENS(i));
    }
  }

  /**
   * @dev Deposit tokens to the strategy
   */
  function deposit(
    uint256 _underlyingAmount,
    uint256 _minAmount,
    uint8 _index
  ) external payable {
    require(_index < underlyingTokenAddresses.length, "Invalid index");
    require(
      msg.value > 0 || _underlyingAmount > 0,
      "Deposit amount can't be zero"
    );

    // Update strategy stakers
    harvestRewards();

    // Transfer ERC20 tokens to this contract if non-native
    address tokenAddress = underlyingTokenAddresses[_index];
    bool isNative = tokenAddress == DEFINITIVE_NATIVE_ADDRESS;
    uint256 depositAmount = msg.value;
    if (!isNative) {
      // deposit underlying amount into this contract
      IERC20 underlying = IERC20(underlyingTokenAddresses[_index]);
      underlying.safeTransferFrom(msg.sender, address(this), _underlyingAmount);

      // deposit the underlying amount
      depositAmount = _underlyingAmount;
    }

    // deposit underlying to get LP tokens and put them to work
    uint256 newLPTokens = depositIntoDefinitive(
      depositAmount,
      _minAmount,
      _index,
      isNative
    );

    // Update current staker
    StrategyStaker storage staker = strategyStakers[msg.sender];
    staker.amount = staker.amount + newLPTokens;
    staker.rewardDebt =
      (staker.amount * accumulatedRewardsPerShare) /
      REWARDS_PRECISION;

    // Update strategy
    lpTokensStaked = lpTokensStaked + newLPTokens;

    // Deposit tokens
    emit Deposit(msg.sender, newLPTokens);
  }

  /**
   * @dev Withdraw tokens from the strategy
   */
  function withdraw(
    uint256 _lpTokenAmount,
    uint256 _minAmount,
    uint8 _index
  ) public {
    StrategyStaker storage staker = strategyStakers[msg.sender];
    require(_index < underlyingTokenAddresses.length, "Invalid index");

    // Withdraw all if amount is greater than staked
    if (_lpTokenAmount > staker.amount) {
      _lpTokenAmount = staker.amount;
    }

    // Pay rewards
    harvestRewards();

    // burn reward tokens and get token credits
    uint256 rewardTokenBalance = rewardToken.balanceOf(msg.sender);

    // figure out how much to withdraw from definitive vault
    uint256 amountToWithdraw = _lpTokenAmount + rewardTokenBalance;

    require(amountToWithdraw > 0, "Nothing to withdraw");

    rewardToken.burn(msg.sender, rewardTokenBalance);

    // Update staker
    staker.amount = staker.amount - _lpTokenAmount;
    staker.rewardDebt =
      (staker.amount * accumulatedRewardsPerShare) /
      REWARDS_PRECISION;

    // Update strategy
    lpTokensStaked = lpTokensStaked - _lpTokenAmount - rewardTokenBalance;

    // Withdraw from definitive vault and include reward token balances
    uint256 underlyingAmount = withdrawFromDefinitive(
      _index,
      _minAmount,
      amountToWithdraw
    );

    emit Withdraw(msg.sender, underlyingAmount);

    // Transfer ERC20 tokens to this contract if non-native
    address tokenAddress = underlyingTokenAddresses[_index];
    bool isNative = tokenAddress == DEFINITIVE_NATIVE_ADDRESS;

    // Transfer to user
    if (isNative) {
      payable(msg.sender).transfer(underlyingAmount);
    } else {
      IERC20 underlying = IERC20(underlyingTokenAddresses[_index]);
      underlying.transfer(msg.sender, underlyingAmount);
    }
  }

  /*
   * @dev Withdraw all tokens from the strategy
   */
  function withdrawAll(uint8 _index, uint256 _minAmount) external {
    uint256 lpTokenAmount = strategyStakers[msg.sender].amount;
    withdraw(lpTokenAmount, _minAmount, _index);
  }

  /**
   * @dev Harvest user rewards
   */
  function harvestRewards() public {
    // 0. Definitive Vault LP tokens - this LP tokens = new rewards
    uint256 newRewards = definitiveVault.getAmountStaked() - lpTokensStaked;

    // 1. update the number of LP tokens staked
    lpTokensStaked = lpTokensStaked + newRewards;

    // 2. Pass rewards
    updatePoolRewards(newRewards);
    StrategyStaker storage staker = strategyStakers[msg.sender];

    uint256 rewardsToHarvest = ((staker.amount * accumulatedRewardsPerShare) /
      REWARDS_PRECISION) - staker.rewardDebt;

    if (rewardsToHarvest == 0) {
      staker.rewardDebt =
        (staker.amount * accumulatedRewardsPerShare) /
        REWARDS_PRECISION;
      return;
    }

    staker.rewardDebt =
      (staker.amount * accumulatedRewardsPerShare) /
      REWARDS_PRECISION;
    emit HarvestRewards(msg.sender, rewardsToHarvest);

    // 3. Transfer rewards
    rewardToken.mint(msg.sender, rewardsToHarvest);
  }

  /**
   * @dev Update strategy's accumulatedRewardsPerShare and lastRewardedBlock
   */
  function updatePoolRewards(uint256 _rewards) private {
    if (lpTokensStaked == 0) {
      lastRewardedBlock = block.number;
      return;
    }
    accumulatedRewardsPerShare =
      accumulatedRewardsPerShare +
      ((_rewards * REWARDS_PRECISION) / lpTokensStaked);
    lastRewardedBlock = block.number;
  }

  /////////////////////////// DEFINITIVE VAULT FUNCTIONS ///////////////////////////

  /**
   * @dev Deposit tokens into Definitive vault end-to-end (deposit + enter)
   * @return Staked amount (lpTokens)
   */
  function depositIntoDefinitive(
    uint256 _underlyingAmount,
    uint256 _minAmount,
    uint8 _index,
    bool _isNative
  ) private returns (uint256) {
    uint256[] memory amounts = new uint256[](underlyingTokenAddresses.length);
    amounts[_index] = _underlyingAmount;

    // Re-form the array to only include the deposit token
    uint256[] memory singleDepositAmount = new uint256[](1);
    singleDepositAmount[0] = _underlyingAmount;

    address[] memory singleDepositAddress = new address[](1);
    singleDepositAddress[0] = underlyingTokenAddresses[_index];

    if (_isNative) {
      // Deposit into vault
      definitiveVault.deposit{ value: _underlyingAmount }(
        singleDepositAmount,
        singleDepositAddress
      );
    } else {
      // 1. Approve vault to spend underlying (if not native)
      IERC20 underlying = IERC20(underlyingTokenAddresses[_index]);
      underlying.approve(address(definitiveVault), _underlyingAmount);

      // 2. Deposit into the vault
      definitiveVault.deposit(singleDepositAmount, singleDepositAddress);
    }

    // Enter into the strategy
    return definitiveVault.enter(amounts, _minAmount);
  }

  /**
   * @dev Withdraw tokens from Definitive vault end-to-end (exit + withdraw)
   */
  function withdrawFromDefinitive(
    uint8 _index,
    uint256 _minAmount,
    uint256 lpTokens
  ) private returns (uint256) {
    // 1. Exit from the strategy via LP Tokens
    uint256 underlyingAmount = definitiveVault.exitOne(
      lpTokens,
      _minAmount,
      _index
    );

    // 2. Get the underlying token address
    address tokenAddress = underlyingTokenAddresses[_index];

    // 3. Withdraw from the vault
    definitiveVault.withdraw(underlyingAmount, tokenAddress);

    return underlyingAmount;
  }

  /**
   * @dev Restake "dry" (loose) erc20 tokens or "wet" (unstaked) lp tokens
   */
  function restake(uint256 _minAmount) public returns (uint256) {
    // 1. Stake any unstaked LP tokens for this pool
    IERC20 lpToken = IERC20(definitiveVault.LP_TOKEN());
    uint256 unstakedLPTokens = lpToken.balanceOf(address(definitiveVault));

    if (unstakedLPTokens > 0) {
      definitiveVault.stake(unstakedLPTokens);
    }

    // 2. Provide liquidity for and stake any loose tokens for this pool
    uint256[] memory amounts = new uint256[](underlyingTokenAddresses.length);
    bool hasNonZeroAmount = false;
    for (uint8 i = 0; i < underlyingTokenAddresses.length; i++) {
      uint256 looseTokens = 0;
      if (underlyingTokenAddresses[i] == DEFINITIVE_NATIVE_ADDRESS) {
        looseTokens = address(definitiveVault).balance;
      } else {
        IERC20 underlying = IERC20(underlyingTokenAddresses[i]);
        looseTokens = underlying.balanceOf(address(definitiveVault));
      }

      amounts[i] = looseTokens;
      hasNonZeroAmount = hasNonZeroAmount || looseTokens > 0;
    }

    if (hasNonZeroAmount) {
      return definitiveVault.enter(amounts, _minAmount);
    } else {
      return 0;
    }
  }

  /////////////////////////// VIEW FUNCTIONS ///////////////////////////

  /**
   * @dev Get the base amount of LP tokens staked in the strategy
   * use this to help compute withdrawals
   */
  function getLPTokenBalance(address user) public view returns (uint256) {
    StrategyStaker storage staker = strategyStakers[user];
    return staker.amount;
  }

  /**
   * @dev Get the total amount of LP tokens staked in the strategy
   */
  function getLPTokenBalanceIncludingRewards(
    address user
  ) public view returns (uint256) {
    StrategyStaker storage staker = strategyStakers[user];
    return staker.amount + rewardToken.balanceOf(msg.sender);
  }
}

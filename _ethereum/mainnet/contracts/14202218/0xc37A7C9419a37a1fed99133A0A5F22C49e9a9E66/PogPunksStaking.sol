//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./Accounts.sol";

contract PogPunksStaking is
  Ownable,
  IERC721Receiver,
  ReentrancyGuard,
  Pausable
{
  using EnumerableSet for EnumerableSet.UintSet;

  address public stakingDestinationAddress;
  address public erc20Address;

  uint256 public expiration;
  uint256 public baseRate;
  uint256 public additionalRate;
  uint256 public totalTokensDeposited;
  uint256 public rewardLevel;
  uint256 public rewardLevelInterval;
  uint256 public supplyDenominator;
  Accounts public accounts;

  mapping(address => EnumerableSet.UintSet) private deposits;
  mapping(address => mapping(uint256 => uint256)) public depositBlocks;
  mapping(address => uint256) private balances;

  event RewardLevelChanged(uint256 oldRewardLevel, uint256 newRewardLevel);

  constructor(
    address _stakingDestinationAddress,
    address _erc20Address,
    uint256 _expiration,
    uint256 _rewardsPerDay,
    uint256 _additionalRewardsPerDay,
    uint256 _blocksPerDay,
    uint256 _supplyDenominator,
    uint256 _rewardLevelInterval
  ) {
    stakingDestinationAddress = _stakingDestinationAddress;
    expiration = block.number + _expiration;
    erc20Address = _erc20Address;
    accounts = new Accounts();
    setRate(_rewardsPerDay, _additionalRewardsPerDay, _blocksPerDay);
    supplyDenominator = _supplyDenominator;
    rewardLevelInterval = _rewardLevelInterval;
    _pause();
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Set a multiplier for how many tokens to earn for each block.
   *         Token rewards scale based on the percentage of total PogPunks that are staked.
   * @param rewardsPerDay The staking rewards per day.
   * @param additionalRewardsPerDay The max amount of additional staking rewards per day.
   * @param blocksPerDay The number of ETH blocks mined per day.
   */
  function setRate(
    uint256 rewardsPerDay,
    uint256 additionalRewardsPerDay,
    uint256 blocksPerDay
  ) public onlyOwner {
    baseRate = (rewardsPerDay * 1e18) / blocksPerDay;
    additionalRate = (additionalRewardsPerDay * 1e18) / blocksPerDay;
  }

  /**
   * @notice Set a reward level interval. Additional staking rewards are unlocked after
   *         reaching a new interval.
   * @param _rewardLevelInterval The interval between each reward level.
   */
  function setRewardLevelInterval(uint256 _rewardLevelInterval)
    external
    onlyOwner
  {
    rewardLevelInterval = _rewardLevelInterval;
  }

  /**
   * @notice Set a supply denominator. To calculate rewards, additionalRate is
   *         scaled based on percentage of PogPunks staked. Percentage of
   *         PogPunks staked is calculated by: totalPogPunksStaked/supplyDenominator.
   * @param _supplyDenominator The denominator used to scale additionalRate for
   *                           calculating staking rewards.
   */
  function setSupplyDenominator(uint256 _supplyDenominator) external onlyOwner {
    supplyDenominator = _supplyDenominator;
  }

  /**
   * @notice Expire staking after an amount of blocks are mined.
   * @param _expiration The number of blocks that are mined before
   *                    staking expires.
   */
  function setExpiration(uint256 _expiration) external onlyOwner {
    expiration = block.number + _expiration;
  }

  /**
   * @notice Check deposits for account.
   * @param account The account to check deposits for.
   */
  function depositsOf(address account)
    external
    view
    returns (uint256[] memory)
  {
    EnumerableSet.UintSet storage depositSet = deposits[account];
    uint256[] memory tokenIds = new uint256[](depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  /**
   * @notice Calculate total rate of rewards.
   * @dev Calculation:
   *   Base rate = $PAO per block for each PogPunk staked
   *   Scaled additional rate = Additional $PAO per block for each PogPunk
   *                            staked scaled by total PogPunks staked
   *   Total = base rate + scaled additional rate
   */
  function calculateTotalRate() public view returns (uint256) {
    return baseRate + ((rewardLevel * additionalRate) / 1e2);
  }

  /**
   * @notice Calculate total rewards for a stakeholder's tokens.
   * @param account The stakeholder to calculate total rewards for.
   * @param tokenIds The stakeholder's tokens to calculate total rewards for.
   * @dev total rewards = current rewards + outstanding balance
   */
  function calculateTotalRewards(address account, uint256[] memory tokenIds)
    public
    view
    returns (uint256 rewards)
  {
    for (uint256 i; i < tokenIds.length; i++) {
      rewards += calculateReward(account, tokenIds[i]);
    }

    if (balances[account] > 0) {
      rewards += balances[account];
    }

    return rewards;
  }

  /**
   * @notice Calculate rewards for a stakeholder's tokens.
   * @param account The stakeholder to calculate rewards for.
   * @param tokenIds The stakeholder's tokens to calculate rewards for.
   */
  function calculateRewards(address account, uint256[] memory tokenIds)
    public
    view
    returns (uint256[] memory rewards)
  {
    rewards = new uint256[](tokenIds.length);

    for (uint256 i; i < tokenIds.length; i++) {
      rewards[i] = calculateReward(account, tokenIds[i]);
    }

    return rewards;
  }

  /**
   * @notice Calculate rewards for an account's deposited token.
   * @param account The account to calculate rewards for.
   * @param tokenId The account's deposited token (id) to calculate rewards for.
   */
  function calculateReward(address account, uint256 tokenId)
    private
    view
    returns (uint256)
  {
    require(
      Math.min(block.number, expiration) >= depositBlocks[account][tokenId],
      "Invalid blocks"
    );

    return
      calculateTotalRate() *
      (deposits[account].contains(tokenId) ? 1 : 0) *
      (Math.min(block.number, expiration) - depositBlocks[account][tokenId]);
  }

  /**
   * @notice Claim rewards for tokens.
   * @param tokenIds The ids of the tokens to claim rewards for.
   */
  function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
    uint256 reward;
    uint256 currentBlock = Math.min(block.number, expiration);

    for (uint256 i; i < tokenIds.length; i++) {
      reward += calculateReward(msg.sender, tokenIds[i]);
      depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
    }

    if (reward > IERC20(erc20Address).balanceOf(address(this))) {
      revert("Insufficient balance");
    }

    if (balances[msg.sender] > 0) {
      reward += balances[msg.sender];
      balances[msg.sender] = 0;
    }

    if (reward > 0) {
      IERC20(erc20Address).transfer(msg.sender, reward);
    }
  }

  /**
   * @notice Store all accounts' current accrued rewards at the current
   *         reward level. This method is used before a new reward level
   *         is set.
   */
  function rebalance() external nonReentrant whenNotPaused {
    uint256 currentBlock = Math.min(block.number, expiration);

    address currentAccount = accounts.getFirst();
    while (currentAccount != accounts.HEAD()) {
      uint256 reward;

      EnumerableSet.UintSet storage tokens = deposits[currentAccount];
      for (uint256 i; i < tokens.length(); i++) {
        uint256 depositBlock = depositBlocks[currentAccount][tokens.at(i)];
        if (currentBlock > depositBlock) {
          reward += calculateTotalRate() * (currentBlock - depositBlock);
        }
        depositBlocks[currentAccount][tokens.at(i)] = currentBlock;
      }

      balances[currentAccount] = reward;

      currentAccount = accounts.getNext(currentAccount);
    }

    setNewRewardLevel();
  }

  /**
   * @notice Set a new reward level based on percent of PogPunks staked.
   */
  function setNewRewardLevel() private whenNotPaused {
    uint256 percentageDeposited = ((totalTokensDeposited * 1e2) /
      supplyDenominator);

    rewardLevel =
      percentageDeposited -
      (percentageDeposited % rewardLevelInterval);
  }

  /**
   * @notice Handle a new reward level based on percent of PogPunks staked.
   *         This method is called whenever someone deposits or withdraws from
   *         staking.
   */
  function handleNewRewardLevel() private whenNotPaused {
    uint256 percentageDeposited = (totalTokensDeposited * 1e2) /
      supplyDenominator;

    uint256 newRewardLevel = percentageDeposited -
      (percentageDeposited % rewardLevelInterval);

    if (rewardLevel != newRewardLevel) {
      emit RewardLevelChanged(rewardLevel, newRewardLevel);
    }
  }

  /**
   * @notice Deposit tokens for staking.
   * @param tokenIds The ids of the tokens to deposit for staking.
   */
  function deposit(uint256[] calldata tokenIds) external whenNotPaused {
    require(msg.sender != stakingDestinationAddress, "Invalid address");

    uint256 currentBlock = Math.min(block.number, expiration);

    if (!accounts.isStaking(msg.sender)) {
      accounts.add(msg.sender);
    }

    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(stakingDestinationAddress).safeTransferFrom(
        msg.sender,
        address(this),
        tokenIds[i],
        ""
      );
      deposits[msg.sender].add(tokenIds[i]);
      depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
    }

    totalTokensDeposited += tokenIds.length;

    handleNewRewardLevel();
  }

  /**
   * @notice Withdraw tokens from staking. Claims all rewards for the
   *         tokens before withdrawing them.
   * @param tokenIds The ids of the tokens to withdraw from staking.
   */
  function withdraw(uint256[] calldata tokenIds)
    external
    whenNotPaused
    nonReentrant
  {
    claimRewards(tokenIds);

    for (uint256 i; i < tokenIds.length; i++) {
      require(
        deposits[msg.sender].contains(tokenIds[i]),
        "Staking: token not deposited"
      );

      deposits[msg.sender].remove(tokenIds[i]);

      IERC721(stakingDestinationAddress).safeTransferFrom(
        address(this),
        msg.sender,
        tokenIds[i],
        ""
      );
    }

    totalTokensDeposited -= tokenIds.length;

    if (deposits[msg.sender].length() == 0) {
      accounts.remove(msg.sender);
    }

    handleNewRewardLevel();
  }

  /**
   * @notice Get all accounts that are staking.
   */
  function getAllAccounts() external view returns (address[] memory) {
    return accounts.getAll();
  }

  /**
   * @notice Withdraw ERC20 from the contract.
   */
  function withdrawERC20() external onlyOwner {
    uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
    IERC20(erc20Address).transfer(msg.sender, tokenSupply);
  }

  /**
   * @notice Withdraw PogPunks from the contract.
   */
  function withdrawPogPunks() external onlyOwner {
    address currentAccount = accounts.getFirst();
    while (currentAccount != accounts.HEAD()) {
      EnumerableSet.UintSet storage tokens = deposits[currentAccount];
      for (uint256 i; i < tokens.length(); i++) {
        IERC721(stakingDestinationAddress).safeTransferFrom(
          address(this),
          msg.sender,
          tokens.at(i),
          ""
        );
      }
      currentAccount = accounts.getNext(currentAccount);
    }
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}

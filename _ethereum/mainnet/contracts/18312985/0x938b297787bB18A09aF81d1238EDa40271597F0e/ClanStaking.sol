// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuardUpgradeable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract ClanStaking is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  using SafeMath for uint256;

  using SafeBEP20 for IBEP20;

  // Whether a limit is set for users
  bool public hasUserLimit;

  // Accrued token per share
  uint256 public accTokenPerShare;

  // The block number when CAKE mining ends.
  uint256 public bonusEndBlock;

  // The block number when CAKE mining starts.
  uint256 public startBlock;

  // The block number of the last pool update
  uint256 public lastRewardBlock;

  // The pool limit (0 if none)
  uint256 public poolLimitPerUser;

  // CAKE tokens created per staked tokens every year.
  uint256 public annualRewardPerToken;

  // CAKE tokens created per staked token every block.
  uint256 public blockRewardPerToken;

  //Max Precision
  uint256 constant maxPrecision = uint256(10**30);

  // The reward token
  IBEP20 public rewardToken;

  // The staked token
  IBEP20 public stakedToken;

  //total staking tokens
  uint256 public totalStakingTokens;

  //total reward tokens
  uint256 public totalRewardTokens;

  //freeze strat block
  uint256 public freezeStartBlock;

  //freeze end block;
  uint256 public freezeEndBlock;

  //total blocks to freeze withdraw for after deposit
  uint256 public withdrawFreezeBlocksCount;

  address[] public userList;

  // Info of each user that stakes tokens (stakedToken)
  mapping(address => UserInfo) public userInfo;

  struct UserInfo {
    address addr; //address of user
    uint256 amount; // How many staked tokens the user has provided
    uint256 rewardDebt; // Reward debt
    uint256 withdrawFreezeEndBlock;
    bool registered; // it will add user in address list on first deposit
  }

  event AdminTokenRecovery(address tokenRecovered, uint256 amount);
  event Deposit(address indexed user, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 amount);
  event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
  event NewAnnualRewardPerToken(uint256 _annualRewardPerToken);
  event NewFreezeBlocks(uint256 freezeStartBlock, uint256 freezeEndBlock);
  event NewPoolLimit(uint256 poolLimitPerUser);
  event RewardsStop(uint256 blockNumber);
  event Withdraw(address indexed user, uint256 amount);
  event AddRewardTokens(address indexed user, uint256 amount);
  event NewWithdrawFreezeBlocksCount(uint256 blockCount);

  /*
   * @notice Initialize the contract
   * @param _stakedToken: staked token address
   * @param _rewardToken: reward token address
   * @param _annualRewardPerToken: annual reward per staked token (in rewardToken)
   * @param _withdrawFreezeBlocksCount: total blocks to freeze withdraw for after deposit
   * @param _startBlock: start block
   * @param _bonusEndBlock: end block
   * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
   * @param _admin: admin address with ownership
   */
  function initialize(
    IBEP20 _stakedToken,
    IBEP20 _rewardToken,
    uint256 _annualRewardPerToken,
    uint256 _withdrawFreezeBlocksCount,
    uint256 _startBlock,
    uint256 _bonusEndBlock,
    uint256 _poolLimitPerUser,
    address _admin
  ) public initializer {
    __ReentrancyGuard_init();
    __Ownable_init();

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    annualRewardPerToken = _annualRewardPerToken;
    withdrawFreezeBlocksCount = _withdrawFreezeBlocksCount;
    startBlock = _startBlock;
    bonusEndBlock = _bonusEndBlock;

    if (_poolLimitPerUser > 0) {
      hasUserLimit = true;
      poolLimitPerUser = _poolLimitPerUser;
    }

    uint256 decimalsRewardToken = uint256(rewardToken.decimals());
    require(decimalsRewardToken < 30, "Must be inferior to 30");

    uint256 PRECISION_FACTOR = uint256(
      10**(uint256(30).sub(decimalsRewardToken))
    );

    blockRewardPerToken = annualRewardPerToken.mul(PRECISION_FACTOR).div(
      10512000
    );

    // Set the lastRewardBlock as the startBlock
    lastRewardBlock = startBlock;

    // Transfer ownership to the admin address who becomes owner of the contract
    transferOwnership(_admin);
  }

  /*
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function deposit(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Contract is frozen");
    UserInfo storage user = userInfo[msg.sender];

    if (hasUserLimit) {
      require(
        _amount.add(user.amount) <= poolLimitPerUser,
        "User amount above limit"
      );
    }

    _updatePool();

    if (user.amount > 0) {
      uint256 pending = user.amount.mul(accTokenPerShare).div(maxPrecision).sub(
        user.rewardDebt
      );
      if (pending > 0) {
        _safeRewardTransfer(address(msg.sender), pending);
      }
    } else if (user.registered == false) {
      userList.push(msg.sender);
      user.registered = true;
      user.addr = address(msg.sender);
    }

    if (_amount > 0) {
      user.amount = user.amount.add(_amount);
      stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      totalStakingTokens = totalStakingTokens.add(_amount);
      if (withdrawFreezeBlocksCount > 0) {
        user.withdrawFreezeEndBlock = block.number.add(
          withdrawFreezeBlocksCount
        );
      }
    }

    user.rewardDebt = user.amount.mul(accTokenPerShare).div(maxPrecision);

    emit Deposit(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function withdraw(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Contract is frozen");
    require(
      _amount == 0 || isUserWithdrawFrozen(msg.sender) == false,
      "User withdraw is frozen"
    );

    UserInfo storage user = userInfo[msg.sender];
    require(user.amount >= _amount, "Amount to withdraw too high");

    _updatePool();

    uint256 pending = user.amount.mul(accTokenPerShare).div(maxPrecision).sub(
      user.rewardDebt
    );

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      stakedToken.safeTransfer(address(msg.sender), _amount);
      totalStakingTokens = totalStakingTokens.sub(_amount);
    }

    if (pending > 0) {
      _safeRewardTransfer(address(msg.sender), pending);
    }

    user.rewardDebt = user.amount.mul(accTokenPerShare).div(maxPrecision);

    emit Withdraw(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens without caring about rewards rewards
   * @dev Needs to be for emergency.
   */
  function emergencyWithdraw() external nonReentrant {
    require(isFrozen() == false, "Contract is frozen");
    require(
      isUserWithdrawFrozen(msg.sender) == false,
      "User withdraw is frozen"
    );

    UserInfo storage user = userInfo[msg.sender];
    uint256 amountToTransfer = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    if (amountToTransfer > 0) {
      stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
      totalStakingTokens = totalStakingTokens.sub(amountToTransfer);
    }

    emit EmergencyWithdraw(msg.sender, user.amount);
  }

  /*
   * @notice return length of user addresses
   */
  function getUserListLength() external view returns (uint256) {
    return userList.length;
  }

  /*
   * @notice View function to get users.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUsersPaging(uint256 _offset, uint256 _limit)
    public
    view
    returns (
      UserInfo[] memory users,
      uint256 nextOffset,
      uint256 total
    )
  {
    uint256 totalUsers = userList.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers.sub(_offset)) {
      _limit = totalUsers.sub(_offset);
    }

    UserInfo[] memory values = new UserInfo[](_limit);
    for (uint256 i = 0; i < _limit; i++) {
      values[i] = userInfo[userList[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice isFrozed returns if contract is frozen, user cannot call deposit, withdraw, emergencyWithdraw function
   */
  function isFrozen() public view returns (bool) {
    return block.number >= freezeStartBlock && block.number <= freezeEndBlock;
  }

  function isUserWithdrawFrozen(address _user) public view returns (bool) {
    UserInfo storage user = userInfo[_user];
    return block.number <= user.withdrawFreezeEndBlock;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner. Needs to be for emergency.
   */
  function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
    totalRewardTokens = totalRewardTokens.sub(_amount);
    rewardToken.safeTransfer(address(msg.sender), _amount);
  }

  /**
   * @notice It allows the admin to reward tokens
   * @param _amount: amount of tokens
   * @dev This function is only callable by admin.
   */
  function addRewardTokens(uint256 _amount) external onlyOwner {
    totalRewardTokens = totalRewardTokens.add(_amount);
    rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    emit AddRewardTokens(msg.sender, _amount);
  }

  /**
   * @notice It allows the admin to recover wrong tokens sent to the contract
   * @param _tokenAddress: the address of the token to withdraw
   * @param _tokenAmount: the number of tokens to withdraw
   * @dev This function is only callable by admin.
   */
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
    external
    onlyOwner
  {
    require(_tokenAddress != address(stakedToken), "Cannot be staked token");
    require(_tokenAddress != address(rewardToken), "Cannot be reward token");

    IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

    emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner
   */
  function stopReward() external onlyOwner {
    bonusEndBlock = block.number;
  }

  /*
   * @notice Stop Freeze
   * @dev Only callable by owner
   */
  function stopFreeze() external onlyOwner {
    freezeStartBlock = 0;
    freezeEndBlock = 0;
  }

  /*
   * @notice Update pool limit per user
   * @dev Only callable by owner.
   * @param _hasUserLimit: whether the limit remains forced
   * @param _poolLimitPerUser: new pool limit per user
   */
  function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser)
    external
    onlyOwner
  {
    require(hasUserLimit, "Must be set");
    if (_hasUserLimit) {
      require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
      poolLimitPerUser = _poolLimitPerUser;
    } else {
      hasUserLimit = _hasUserLimit;
      poolLimitPerUser = 0;
    }
    emit NewPoolLimit(poolLimitPerUser);
  }

  /*
   * @notice Update reward per staked token
   * @dev Only callable by owner.
   * @param _annualRewardPerToken: reward per staked token
   */
  function updateAnnualRewardPerToken(uint256 _annualRewardPerToken)
    external
    onlyOwner
  {
    require(
      block.number < startBlock || block.number > bonusEndBlock,
      "Pool has started"
    );
    annualRewardPerToken = _annualRewardPerToken;
    uint256 PRECISION_FACTOR = 10**uint256(30).sub(rewardToken.decimals());
    blockRewardPerToken = _annualRewardPerToken.mul(PRECISION_FACTOR).div(
      10512000
    );
    emit NewAnnualRewardPerToken(_annualRewardPerToken);
  }

  /*
   * @notice Update total blocks to freeze withdraw for after deposit
   * @dev Only callable by owner.
   * @param _annualRewardPerToken: reward per staked token
   */
  function updateWithdrawFreezeBlocksCount(uint256 _withdrawFreezeBlocksCount)
    external
    onlyOwner
  {
    require(
      block.number < startBlock || block.number > bonusEndBlock,
      "Pool has started"
    );
    withdrawFreezeBlocksCount = _withdrawFreezeBlocksCount;
    emit NewWithdrawFreezeBlocksCount(_withdrawFreezeBlocksCount);
  }

  /**
   * @notice It allows the admin to update start and end blocks
   * @dev This function is only callable by owner.
   * @param _startBlock: the new start block
   * @param _bonusEndBlock: the new end block
   */
  function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock)
    external
    onlyOwner
  {
    require(
      block.number < startBlock || block.number > bonusEndBlock,
      "Pool has started"
    );
    require(
      _startBlock < _bonusEndBlock,
      "New startBlock must be lower than new end block"
    );
    require(
      block.number < _startBlock,
      "New startBlock must be higher than current block"
    );

    startBlock = _startBlock;
    bonusEndBlock = _bonusEndBlock;

    // Set the lastRewardBlock as the startBlock
    lastRewardBlock = startBlock;

    emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
  }

  /**
   * @notice It allows the admin to update freeze start and end blocks
   * @dev This function is only callable by owner.
   * @param _freezeStartBlock: the new freeze start block
   * @param _freezeEndBlock: the new freeze end block
   */
  function updateFreezeBlocks(
    uint256 _freezeStartBlock,
    uint256 _freezeEndBlock
  ) external onlyOwner {
    require(
      _freezeStartBlock < _freezeEndBlock,
      "New freeze startBlock must be lower than new endBlock"
    );
    require(
      block.number < _freezeStartBlock,
      "freeze start block must be higher than current block"
    );

    freezeStartBlock = _freezeStartBlock;
    freezeEndBlock = _freezeEndBlock;
    emit NewFreezeBlocks(freezeStartBlock, freezeEndBlock);
  }

  function freezeForDays(uint256 _days) external onlyOwner {
    require(_days > 0, "Days to freeze must be greater than 0");
    freezeStartBlock = block.number;
    freezeEndBlock = block.number.add(_days.mul(24).mul(60).mul(20));
    emit NewFreezeBlocks(freezeStartBlock, freezeEndBlock);
  }

  /*
   * @notice View function to see pending reward on frontend.
   * @param _user: user address
   * @return Pending reward for a given user
   */
  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint256 stakedTokenSupply = totalStakingTokens;
    if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
      uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
      uint256 cakeReward = multiplier.mul(blockRewardPerToken);
      uint256 adjustedTokenPerShare = accTokenPerShare.add(cakeReward);
      return
        user.amount.mul(adjustedTokenPerShare).div(maxPrecision).sub(
          user.rewardDebt
        );
    } else {
      return
        user.amount.mul(accTokenPerShare).div(maxPrecision).sub(
          user.rewardDebt
        );
    }
  }

  /*
   * @notice Update reward variables of the given pool to be up-to-date.
   */
  function _updatePool() internal {
    if (block.number <= lastRewardBlock) {
      return;
    }

    uint256 stakedTokenSupply = totalStakingTokens;

    if (stakedTokenSupply == 0) {
      lastRewardBlock = block.number;
      return;
    }

    uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
    uint256 cakeReward = multiplier.mul(blockRewardPerToken);
    accTokenPerShare = accTokenPerShare.add(cakeReward);
    lastRewardBlock = block.number;
  }

  /*
   * @notice Return reward multiplier over the given _from to _to block.
   * @param _from: block to start
   * @param _to: block to finish
   */
  function _getMultiplier(uint256 _from, uint256 _to)
    internal
    view
    returns (uint256)
  {
    if (_to <= bonusEndBlock) {
      return _to.sub(_from);
    } else if (_from >= bonusEndBlock) {
      return 0;
    } else {
      return bonusEndBlock.sub(_from);
    }
  }

  /*
   * @notice transfer reward tokens.
   * @param _to: address where tokens will transfer
   * @param _amount: amount of tokens
   */
  function _safeRewardTransfer(address _to, uint256 _amount) internal {
    uint256 rewardTokenBal = totalRewardTokens;
    if (_amount > rewardTokenBal) {
      totalRewardTokens = totalRewardTokens.sub(rewardTokenBal);
      rewardToken.safeTransfer(_to, rewardTokenBal);
    } else {
      totalRewardTokens = totalRewardTokens.sub(_amount);
      rewardToken.safeTransfer(_to, _amount);
    }
  }
}
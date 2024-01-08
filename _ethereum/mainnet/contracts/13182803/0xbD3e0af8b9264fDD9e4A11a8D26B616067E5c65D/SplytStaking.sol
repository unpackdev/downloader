// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ABDKMath64x64.sol";

/**
 * @title SplytStaking
 * @dev Enables a user to stake tokens into this smart contract
 */
contract SplytStaking is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private _token; // The token to be used in this smart contract

  struct Compound {
    uint depositStartBlock;  // Block where users are allowed to start deposits
    uint depositEndBlock;    // Block where deposits are no longer allowed
    uint interestStartBlock; // Block that starts yield gaining
    uint interestEndBlock;   // Block that ends yield gained
    uint startTime;          // Time to start computing compound yield
    uint endTime;            // Time to stop computing compound yield
    uint apyPerSec;          // Interval at which yield compounds, e.g., 31556952 seconds/year, 8600 hours/year
    uint apyPerBlock;        // Reward per block. We assume 15s per block
  }

  struct activeStaker {
    address addr; // Address of active staker
    uint balance; // Balance of the staker
  }

  Compound private compound;                // Struct to hold compound information
  uint constant secondsPerYear = 31556952;  // Seconds in a year
  uint constant blocksPerMonth = 175200;    // Blocks per month
  uint poolDurationByBlock;                 // How long to yield interest aka max amount of blocks allowed for reward
  uint constant secondPerBlock = 15;        // Number of seconds between blocks mined
  uint feeDivisor = 10**3;                  // Withdrawal fee (0.1%)

  uint totalPrincipal;                     // Total amount of token principal deposited into this smart contract
  uint numUsersWithDeposits;               // Total number of users who have deposited tokens into this smart contract
  uint numUniqueUsers;                     // Total number of unique users who have called stakeTokens() so far

  uint secretBonusLimit;                   // If secretBonusLimit reached, provide bonus to long term holders
  uint secretBonusPool;                    // Pool amount to be distributed

  mapping (address => uint256) public _balances;       // Balance of tokens by user
  mapping (uint256 => address) public addressByIndex;  // Address by index

  /**
   * @dev Emitted when `_amount` tokens are staked by `_userAddress`
   */
  event TokenStaked(address _userAddress, uint256 _amount);

  /**
   * @dev Emitted when `_amount` tokens are withdrawn by `_userAddress`
   */
  event TokenWithdrawn(address _userAddress, uint256 _amount);

  /**
   * @dev Creates the SplytStaking smart contract
   * @param token address of the token to be vested
   * @param _apyPerSec APY gained per second ratio
   * @param _depositStartBlock Block where deposits start
   * @param _depositEndBlock Block where deposits end
   */
  constructor (
    address token,
    uint _apyPerSec,
    uint _depositStartBlock,
    uint _depositEndBlock,
    uint _poolDurationByBlock,
    uint _secretBonusLimit,
    uint _secretBonusPool
  ) public {
    _token = IERC20(token);

    // Set how long the pool will yield interest
    poolDurationByBlock = _poolDurationByBlock;

    // set bonus pool params
    secretBonusLimit = _secretBonusLimit;
    secretBonusPool = _secretBonusPool;

    // Compute start and end blocks for yield compounding
    uint interestStartBlock = _depositEndBlock.add(1);
    uint interestEndBlock = interestStartBlock.add(poolDurationByBlock);

    // Compute start and end times for the same time period
    uint blocksUntilInterestStarts = interestStartBlock.sub(block.number);
    uint interestStartTime = block.timestamp.add(blocksUntilInterestStarts.mul(secondPerBlock));
    uint blocksUntilInterestEnd = interestEndBlock.sub(interestStartBlock);
    uint interestEndTime = block.timestamp.add(blocksUntilInterestEnd.mul(secondPerBlock));

    compound = Compound({
      depositStartBlock: _depositStartBlock,
      depositEndBlock: _depositEndBlock,
      interestStartBlock: interestStartBlock,
      interestEndBlock: interestEndBlock,
      startTime: interestStartTime,
      endTime: interestEndTime,
      apyPerSec: _apyPerSec,
      apyPerBlock: _apyPerSec.mul(secondPerBlock)
    });

    numUsersWithDeposits = 0;
    totalPrincipal = 0;
    numUniqueUsers = 0;
    _balances[address(this)] = 0;
  }

  // -----------------------------------------------------------------------
  // Modifiers
  // -----------------------------------------------------------------------

  /**
   * @dev Modifier that only lets the function continue if it is within the deposit window (depositStartBlock, depositEndBlock)
   */
  modifier depositWindow() {
    require (block.number > compound.depositStartBlock && block.number <= compound.depositEndBlock, "DepositWindow: Can be called only during deposit window");
    _;
  }

  /**
   * @dev Modifier that only lets the function continue if the current block is before compound.interestStartBlock
   */
  modifier hasNotStartedYielding() {
    require (block.number < compound.interestStartBlock, "HasNotStartedYielding: Can be called only before interest start block");
    _;
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /**
   * @dev Check that the amount of blocks staked does not exceed limit: poolBlockDuration=maxBlock.
   * @dev If a user keeps their tokens longer than maxBlock, they only get yield up to maxBlock.
   * @param numBlocksPassed Amount of blocks passed
   * @param maxBlock Highest amount of blocks allowed to pass (limit)
   */
  function _blocksStaked(uint numBlocksPassed, uint maxBlock) public pure returns (uint) {
    if(numBlocksPassed >= maxBlock) {
      return maxBlock;
    } else {
      return numBlocksPassed;
    }
  }

  // -----------------------------------------------------------------------
  // COMPUTATIONS
  // -----------------------------------------------------------------------

  /**
   * @dev Estimates the power computation
   * @param x base
   * @param n duration
   */
  function pow (int128 x, uint n) public pure returns (int128 r) {
    r = ABDKMath64x64.fromUInt (1);  while (n > 0) {
    if (n % 2 == 1) {
      r = ABDKMath64x64.mul (r, x);
      n -= 1;
    } else {
      x = ABDKMath64x64.mul (x, x);
      n /= 2;
    }
  }
  }

  /**
   * @dev Method to compute APY gained. Note: this is only used for comparison, not actually used to compute real gain
   * @param principal Principal provided
   * @param ratio Amount of APY gained per second
   * @param n Duration
   */
  function compoundInterestByTime(uint principal, uint ratio, uint n) public pure returns (uint) {
    return ABDKMath64x64.mulu (
      pow (
        ABDKMath64x64.add (ABDKMath64x64.fromUInt (1), ABDKMath64x64.divu (ratio, 10**18)),
        n),
      principal);
  }

  /**
   * @dev Wrapper method that is bound to the smart contract apyPerSec variable
   * @dev Enables durations to be set manually
   * @dev Not used to compute real gain
   * @param principal Principal provided
   * @param duration Duration
   * @return the amount gained: principal + yield
   */
  function compoundWithPrincipalAndTime(uint principal, uint duration) external view returns (uint) {
    return compoundInterestByTime(principal, compound.apyPerSec, duration);
  }

  /**
   * @dev Wrapper method that is bound to the smart contract apyPerSec and computes duration against live blockchain data
   * @dev Not used to compute real gain
   * @param principal Principal provided
   * @return the amount gained: principal + yield
   */
  function compoundWithPrincipal(uint principal) public view returns (uint) {
    uint duration = block.timestamp - compound.startTime;
    return compoundInterestByTime(principal, compound.apyPerSec, duration);
  }

  /**
   * @dev Wrapper method that computes gain using the callers information
   * @dev Uses all predefined variables in the smart contract and blockchain state
   * @dev Not used to compute real gain
   * @return the amount gained: principal + yield
   */
  function compoundWithPrincipalByUser() external view returns (uint) {
    return compoundWithPrincipal(_balances[msg.sender]);
  }

  /**
   * @dev Raw method that computes gain using blocks instead of time
   * @param principal Principal provided
   * @param blocksStaked Number of blocks with which to compute gain
   * @return the amount gained: principal + yield
   */
  function _compoundInterestByBlock(uint principal, uint blocksStaked) public view returns (uint) {
    uint reward = SafeMath.div(compound.apyPerBlock.mul(principal).mul(blocksStaked), 10**18);
    return reward.add(principal);
  }

  /**
   * @dev Computes yield gained using block raw function
   * @dev Makes sure that a user cannot gain more yield than poolBlockDuration as defined in the smart contract
   * @param principal Principal
   * @return the amount gained: principal + yield
   */
  function compoundInterestByBlock(uint principal) public view returns (uint) {
    uint numBlocksPassed = block.number.sub(compound.interestStartBlock);
    uint blocksStaked = _blocksStaked(numBlocksPassed, poolDurationByBlock);
    return _compoundInterestByBlock(principal, blocksStaked);
  }

  // -----------------------------------------------------------------------
  // GETTERS
  // -----------------------------------------------------------------------

  /**
   * @dev Gets block and time information out of the smart contract
   * @return _currentBlock Current block on the blockchain
   * @return _depositStartBlock Block where deposits are allowed
   * @return _depositEndBlock Block where deposits are no longer allowed
   * @return _interestStartBlock Block where yield starts growing
   * @return _interestEndBlock Block where yield stops growing
   * @return _interestStartTime Estimated yield start time (for comparison only)
   * @return _interestEndTime Estimated yield end time (for comparison only)
   * @return _interestApyPerSec APY per second rate defined in the smart contract
   * @return _interestApyPerBlock APY per block defined in the smart contract
   */
  function getCompoundInfo() external view returns (
    uint _currentBlock,
    uint _depositStartBlock,
    uint _depositEndBlock,
    uint _interestStartBlock,
    uint _interestEndBlock,
    uint _interestStartTime,
    uint _interestEndTime,
    uint _interestApyPerSec,
    uint _interestApyPerBlock
  ) {
    return (
    block.number,
    compound.depositStartBlock,
    compound.depositEndBlock,
    compound.interestStartBlock,
    compound.interestEndBlock,
    compound.startTime,
    compound.endTime,
    compound.apyPerSec,
    compound.apyPerBlock
    );
  }

  /**
 * @dev Gets info about secret pool. :P
 * @return _secretBonusLimit Number of wallets who need to stake to unlock the secretBonusPool
 * @return _secretBonusPool Total pool that will be divided by all users who stay for the entire duration (see withdrawTokens fn)
 * @return _bonusUnlockable Bool is true if number of users who stake is over  _secretBonusLimit
 * @return _bonusUnlocked Bool controls if the bonus is going to be applied (see withdrawTokens fn)
 */
  function getSecretPoolInfo() public view returns (uint _secretBonusLimit, uint _secretBonusPool, bool _bonusUnlockable, bool _bonusUnlocked) {
    return (
      secretBonusLimit,
      secretBonusPool,
      numUniqueUsers > secretBonusLimit,
      block.number >= compound.interestEndBlock && numUniqueUsers > secretBonusLimit
    );
  }

  /**
   * @dev Gets staking data from this smart contract
   * @return _totalPrincipal Total amount of tokens deposited as principal
   * @return _numUsersWithDeposits Number of users who have staked into this smart contract
   */
  function getAdminStakingInfo() public view returns (uint _totalPrincipal, uint _numUsersWithDeposits) {
    return (totalPrincipal, numUsersWithDeposits);
  }

  /**
   * @dev Gets user balance data
   * @dev If this is called before any yield is gained, we manually display 0 reward
   * @param userAddress Address of a given user
   * @return _principal Principal that a user has staked
   * @return _reward Current estimated reward earned
   * @return _balance Total balance (_principal + _reward)
   */
  function getUserBalances(address userAddress) external view returns (uint _principal, uint _reward, uint _balance) {
    if(block.number <= compound.interestStartBlock) {
      return (
      _balances[userAddress],
      0,
      _balances[userAddress]);
    } else {
      uint totalBalance = compoundInterestByBlock(_balances[userAddress]);
      uint reward = totalBalance.sub(_balances[userAddress]);
      return (
      _balances[userAddress],
      reward,
      totalBalance
      );
    }
  }

  /**
   * @dev Get list of active stakers and balances
   * @return {{addr, balance},...} as an array
   */
//  function getActiveStakers() public view returns (activeStaker[] memory) {
//    // Array of structs for active stakers
//    activeStaker[] memory activeStakers = new activeStaker[](numUsersWithDeposits);
//    uint i = 0; // index for activeStakers[]
//    uint j = 0; // index for addressByIndex[]
//    for (; i < numUsersWithDeposits ; j++) {
//      // If balances is zero, consider the address as an inactive staker
//      if (_balances[addressByIndex[j]] != 0) {
//        activeStakers[i].addr = addressByIndex[j];
//        activeStakers[i].balance = _balances[addressByIndex[j]];
//        i++;
//      }
//    }
//    return (activeStakers);
//  }

  /**
   * @dev Reads the APY defined in the smart contract as a percentage
   * @return _apy APY in percentage form
   */
  function apy() external view returns (uint _apy) {
    return secondsPerYear * compound.apyPerSec * 100;
  }

  // -----------------------------------------------------------------------
  // SETTERS
  // -----------------------------------------------------------------------

  /**
   * @dev Enables the deposit window to be changed. Only the smart contract owner is allowed to do this
   * @dev Because blocks are not always found at the same rate, we may need to change the deposit window so events start on time
   * @dev We will only call this so the start time is as accurate as possible
   * @dev We have to recompute the yield start block and yield end block times as well
   * @param _depositStartBlock New deposit start block
   * @param _depositEndBlock New deposit end block
   */
  function changeDepositWindow(uint _depositStartBlock, uint _depositEndBlock) external onlyOwner {
    compound.depositStartBlock = _depositStartBlock;
    compound.depositEndBlock = _depositEndBlock;
    compound.interestStartBlock = _depositEndBlock.add(1);
    compound.interestEndBlock = compound.interestStartBlock.add(poolDurationByBlock);

    uint blocksUntilInterestStarts = compound.interestStartBlock.sub(block.number);
    compound.startTime = block.timestamp.add(blocksUntilInterestStarts.mul(secondPerBlock));

    uint blocksUntilInterestEnd = compound.interestEndBlock.sub(compound.interestStartBlock);
    compound.endTime = block.timestamp.add(blocksUntilInterestEnd.mul(secondPerBlock));
  }

    /**
   * @dev Change the APY of the contract. Only the smart contract owner is allowed to do this
   * @dev The method should only be callable by the owner AND only if the current block is before compound.interestStartBlock
   * @param _newApyRate New APY 
   */

  function changeAPY(uint _newApyRate) external onlyOwner hasNotStartedYielding {    
    compound.apyPerSec = _newApyRate;
    compound.apyPerBlock = _newApyRate.mul(secondPerBlock);
  }

  /**
   * @dev Enables a user to deposit their stake into this smart contract. A user must call approve tokens before calling this method
   * @dev This can only be called during the deposit window. Calling this before or after will fail
   * @dev We also make sure to track the state of [totalPrincipal, numUsersWithDeposits]
   * @param _amount The amount of tokens to stake into this smart contract
   */
  function stakeTokens(uint _amount) external depositWindow {
    require(_token.allowance(msg.sender, address(this)) >= _amount, "TokenBalance: User has not allowed tokens to be used");
    require(_token.balanceOf(msg.sender) >= _amount, "TokenBalance: msg.sender can not stake more than they have");

    if(_balances[msg.sender] == 0) {
      numUsersWithDeposits++;
      numUniqueUsers++;
//      addressByIndex[numUniqueUsers++] = msg.sender;
    }

    _balances[msg.sender] += _amount;
    totalPrincipal += _amount;

    require(_token.transferFrom(msg.sender, address(this), _amount), "TokenTransfer: failed to transfer tokens from msg.sender here");
    emit TokenStaked(msg.sender, _amount);
  }


  /**
   * @dev Lets a user withdraw all their tokens from this smart contract
   * @dev A fee is charged on all withdrawals
   * @dev We make sure to track the state of [totalPrincipal, numUsersWithDeposits]
   */
  function withdrawTokens() external {
    require(_balances[msg.sender] > 0, "TokenBalance: no tokens available to be withdrawn");

    uint totalBalance = 0;

    if(block.number <= compound.depositEndBlock) {
      totalBalance = _balances[msg.sender];
    } else {
      totalBalance = compoundInterestByBlock(_balances[msg.sender]);
    }
    uint fee = totalBalance.div(feeDivisor);
    totalBalance = totalBalance.sub(fee);

    if(block.number >= compound.interestEndBlock && numUniqueUsers > secretBonusLimit) {
      totalBalance += secretBonusPool.div(numUniqueUsers);
    }

    totalPrincipal -= _balances[msg.sender];
    _balances[msg.sender] = 0;
    numUsersWithDeposits -= 1;

    require(_token.transfer(msg.sender, totalBalance));
    emit TokenWithdrawn(msg.sender, totalBalance);
  }

  /**
   * @dev Computes the amount of tokens the owner is allowed to withdraw
   * @dev Assumes owner deposited tokens at the end of the deposit window, and not all users stay for the full 30 days
   * @dev There will be a remainder because users leave before the 30 days is over. Owner withdraws the balance
   */
  function adminWithdrawRemaining() external onlyOwner {
    uint totalBalanceNeeded = compoundInterestByBlock(totalPrincipal);
    uint contractBalance = _token.balanceOf(address(this));

    // We deposit tokens and assume everyone gains yield for the full 30 days
    // There is a difference because some users will withdraw tokens before the 30 days is over
    if(contractBalance > totalBalanceNeeded) {
      uint extraTokenBalance = contractBalance.sub(totalBalanceNeeded);
      require(_token.transfer(msg.sender, extraTokenBalance));
      emit TokenWithdrawn(msg.sender, extraTokenBalance);
    }
  }

  /**
   * @dev Lets owner, and only the owner, withdraw any amount of tokens
   * @dev ONLY TO BE CALLED IN A CATASTROPHIC SCENARIO!!!
   * @param _amount Number of tokens to withdraw
   */
  function withdrawExtraTokens(uint _amount) external onlyOwner {
    require(_token.transfer(msg.sender, _amount));
    emit TokenWithdrawn(msg.sender, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Address.sol";
import "./SafeCast.sol";
import "./IERC20.sol";
import "./SafeERC20Upgradeable.sol";

import "./IRarityPool.sol";
import "./IRareStakingRegistry.sol";

/// @author koloz, charlescrain
/// @title RarityPool
/// @notice The Staked ERC20 contract that allows users to stake/unstake/claim rewards/reward swaps.
/// @dev It is one base user per contract. This is the implementation contract for a beacon proxy.
contract RarityPool is IRarityPool, ERC20SnapshotUpgradeable, ReentrancyGuardUpgradeable {
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

  using Address for address payable;
  using SafeCast for uint256;

  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/
  // Round # -> Reward Amount
  mapping(uint256 => uint256) private roundRewardAmount;

  // Last round claimed by user
  mapping(address => uint256) private lastRoundClaimedByUser;

  // Amount staked per user
  mapping(address => uint256) private amountStakedByUser;

  // The address of the target being staked on
  address private targetStakedTo;

  // Address of the staking registry
  IRareStakingRegistry private stakingRegistry;

  // Sum of all the rewards, only updated during snapshots
  uint256 private sumOfAllRewards;

  // Sum of the total amount claimed
  uint256 private sumOfAllClaimed;

  // Intial start for rounds
  uint256 private periodStart;

  // Last snapshot timestamp
  uint256 private lastSnapshotTimestamp;

  /*//////////////////////////////////////////////////////////////////////////
                              Constructor
  //////////////////////////////////////////////////////////////////////////*/
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/
  function initialize(
    address _userStakedTo,
    address _stakingRegistry,
    address _creator
  ) public initializer {
    if (_userStakedTo == address(0)) revert ZeroAddressUnsupported();
    if (_stakingRegistry == address(0)) revert ZeroAddressUnsupported();
    if (_creator == address(0)) revert ZeroAddressUnsupported();
    __ERC20Snapshot_init();
    targetStakedTo = _userStakedTo;
    stakingRegistry = IRareStakingRegistry(_stakingRegistry);
    periodStart = block.timestamp;
    lastSnapshotTimestamp = 0;
    _mint(_creator, 1 ether);
    _snapshot(); // we do this increment the counter so rounds and snapshot IDs are equal.
    takeSnapshot();
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRarityPool
  function addRewards(address _donor, uint256 _amount) public {
    if (_donor != msg.sender && msg.sender != stakingRegistry.getStakingInfoForUser(targetStakedTo).rewardAddress) {
      revert IRarityPool.Unauthorized();
    }

    // Cannot send 0 rewards
    if (_amount == 0) revert IRarityPool.CannotAddZeroRewards();

    takeSnapshot();

    // Get current round
    uint256 roundToUpdate = getCurrentRound();

    // If there are no stakers, transfer the rewards to the default payee
    if (totalSupplyAt(roundToUpdate) == 0) {
      stakingRegistry.transferRareFrom(_donor, stakingRegistry.getDefaultPayee(), _amount);
      return;
    }

    // Attribute rewards and any excess RARE stored in the contract
    // excess rare = Total RARE balance - RARE staked - unclaimed RARE aka (all rewards - claimed rewards)
    uint256 additionalRoundRewards = _amount +
      (ERC20BurnableUpgradeable(stakingRegistry.getRareAddress()).balanceOf(address(this)) -
        stakingRegistry.getTotalAmountStakedOnUser(targetStakedTo) -
        (sumOfAllRewards - sumOfAllClaimed));

    // Add new round reward.
    sumOfAllRewards += additionalRoundRewards;
    roundRewardAmount[roundToUpdate] += additionalRoundRewards;

    // Transfer the RARE in
    stakingRegistry.transferRareFrom(_donor, address(this), _amount);

    emit AddRewards(_donor, roundToUpdate, _amount, additionalRoundRewards, roundRewardAmount[roundToUpdate]);
  }

  /// @inheritdoc IRarityPool
  /// @dev Anyone can make this call.
  function takeSnapshot() public {
    // Snapshots can only occur if the period length has past.
    if (lastSnapshotTimestamp + stakingRegistry.getPeriodLength() <= block.timestamp) {
      uint256 oldsnapshotTimestamp = lastSnapshotTimestamp;
      lastSnapshotTimestamp = block.timestamp;
      _snapshot();
      emit StakingSnapshot(oldsnapshotTimestamp, lastSnapshotTimestamp, getCurrentRound());
    }
  }

  /// @inheritdoc IRarityPool
  /// @dev Caller must have given this contract allowance for their $RARE tokens.
  /// @dev On each call will check to see if the period needs to be updated.
  /// @dev Amount of synthetic token received is determined by a sqrt bonding curve.
  function stake(uint120 _amount) external nonReentrant {
    takeSnapshot();

    // Set the last round claimed so the when the user claims they do not have to claim for prior rounds with no stake.
    if (balanceOf(msg.sender) == 0) {
      lastRoundClaimedByUser[msg.sender] = getCurrentRound() - 1;
    }
    // Calculate SRARE to mint
    uint256 amountSRare = calculatePurchaseReturn(totalSupply().toUint120(), _amount);

    // Move staked amount into pool
    IRareStakingRegistry registry = stakingRegistry;
    registry.transferRareFrom(msg.sender, address(this), _amount);

    // Update amount staked by user on pool and on registry
    amountStakedByUser[msg.sender] += _amount;
    registry.increaseAmountStaked(msg.sender, targetStakedTo, _amount);

    // Mint new SRARE to staker
    _mint(msg.sender, amountSRare);
    emit Stake(msg.sender, _amount, amountStakedByUser[msg.sender], amountSRare);
  }

  /// @inheritdoc IRarityPool
  /// @dev On each call will check to see if the period needs to be updated.
  /// @dev Amount of $RARE received is the % of your synthetic tokens unstaked.
  /// @dev {deflationaryPercentage} of the unstaked rare is burned.
  function unstake(uint256 _amount) external nonReentrant {
    takeSnapshot();

    // Check SRARE balance of sender
    uint256 srareBalance = balanceOf(msg.sender);
    if (_amount > srareBalance) {
      revert InsufficientSyntheticRare();
    }

    // Calculate and check amount of staked RARE to return
    uint256 amtStaked = amountStakedByUser[msg.sender];
    uint256 amountRareReturned = calculateSaleReturn(balanceOf(msg.sender), amtStaked, _amount);
    if (amountRareReturned > amtStaked) {
      revert InsufficientStakedRare();
    }

    // Clean up staked amount on pool and on registry
    amountStakedByUser[msg.sender] = amtStaked - amountRareReturned;
    stakingRegistry.decreaseAmountStaked(msg.sender, targetStakedTo, amountRareReturned);

    // Burn SRARE
    _burn(msg.sender, _amount);

    IRareStakingRegistry registry = stakingRegistry;

    // Perform burn of RARE
    ERC20BurnableUpgradeable rare = ERC20BurnableUpgradeable(registry.getRareAddress());
    uint256 burnAmount = (amountRareReturned * registry.getDeflationaryPercentage()) / 100_00;
    rare.burn(burnAmount);

    // Return staked RARE
    uint256 amountDue = amountRareReturned - burnAmount;
    SafeERC20Upgradeable.safeTransfer(rare, msg.sender, amountDue);

    emit Unstake(msg.sender, amountRareReturned, amtStaked - amountRareReturned, burnAmount, _amount);
  }

  /// @inheritdoc IRarityPool
  /// @dev Will snapshot a new round if possible.
  function claimRewards(address _user, uint8 _numRounds) external nonReentrant {
    takeSnapshot();
    // Throw if claiming no rounds
    if (_numRounds == 0) revert IRarityPool.ClaimingZeroRounds();

    uint256 claimableRound = getCurrentRound() - 1;

    // Throw if claiming current round or later. Implies that all available rounds have been claimed
    if (lastRoundClaimedByUser[_user] >= claimableRound) revert IRarityPool.RewardAlreadyClaimed();

    // Round to claim to is either the current claimable round or the last round claimed + the number of rounds to claim
    uint256 roundToClaimTo = claimableRound - lastRoundClaimedByUser[_user] <= _numRounds
      ? claimableRound
      : lastRoundClaimedByUser[_user] + _numRounds;

    // Build total rewards for claim
    uint256 rewards = 0;
    uint256 currentSnapshotId = _getCurrentSnapshotId();
    for (uint256 i = lastRoundClaimedByUser[_user] + 1; i <= roundToClaimTo; i++) {
      rewards += _getRewardsForUserForRound(_user, i, currentSnapshotId);
    }

    // Set the last round claimed by user to the round they are claiming to
    lastRoundClaimedByUser[_user] = roundToClaimTo;

    // Transfer rewards
    SafeERC20Upgradeable.safeTransfer( ERC20BurnableUpgradeable(stakingRegistry.getRareAddress()), _user, rewards);

    // Update total claim amounts
    sumOfAllClaimed += rewards;
    emit RewardClaimed(msg.sender, _user, rewards);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External/Public Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRarityPool
  function getAmountStakedByUser(address _user) external view returns (uint256) {
    return amountStakedByUser[_user];
  }

  /// @inheritdoc IRarityPool
  function name() public view override(IRarityPool, ERC20Upgradeable) returns (string memory) {
    IRareStakingRegistry.Info memory info = stakingRegistry.getStakingInfoForUser(targetStakedTo);
    return info.name;
  }

  /// @inheritdoc IRarityPool
  function symbol() public view override(IRarityPool, ERC20Upgradeable) returns (string memory) {
    IRareStakingRegistry.Info memory info = stakingRegistry.getStakingInfoForUser(targetStakedTo);
    return info.symbol;
  }

  /// @inheritdoc IRarityPool
  function getTargetBeingStakedOn() external view returns (address) {
    return targetStakedTo;
  }

  /// @inheritdoc IRarityPool
  function getRoundRewards(uint256 _round) public view returns (uint256) {
    return roundRewardAmount[_round];
  }

  /// @inheritdoc IRarityPool
  function getHistoricalRewardsForUserForRounds(
    address _user,
    uint256[] memory _rounds
  ) external view returns (uint256) {
    uint256 rewards = 0;
    uint256 currentSnapshotId = _getCurrentSnapshotId();
    for (uint8 i = 0; i < _rounds.length; i++) {
      rewards += _getRewardsForUserForRound(_user, _rounds[i], currentSnapshotId);
    }
    return rewards;
  }

  /// @inheritdoc IRarityPool
  function getClaimableRewardsForUser(address _user, uint256 _numRounds) public view returns (uint256) {
    uint256 rewards = 0;
    uint256 currentRound = getCurrentRound();
    uint256 currentSnapshotId = _getCurrentSnapshotId();
    uint256 roundToClaimTo = currentRound - lastRoundClaimedByUser[_user] > _numRounds
      ? lastRoundClaimedByUser[_user] + _numRounds
      : currentRound;

    for (uint256 i = lastRoundClaimedByUser[_user] + 1; i <= roundToClaimTo; i++) {
      rewards += _getRewardsForUserForRound(_user, i, currentSnapshotId);
    }
    return rewards;
  }

  /// @inheritdoc IRarityPool
  function getCurrentRound() public view returns (uint256) {
    if (block.timestamp < lastSnapshotTimestamp + stakingRegistry.getPeriodLength()) {
      return _getCurrentSnapshotId();
    }
    return _getCurrentSnapshotId() + 1;
  }

  /// @inheritdoc IRarityPool
  /// @dev Calculated based on a sqrt token bonding curve.
  function calculatePurchaseReturn(uint120 _totalSRare, uint120 _stakedAmount) public pure returns (uint256) {
    uint256 totalSRare = uint256(_totalSRare);
    uint256 stakedAmount = uint256(_stakedAmount);
    return (((_sqrt(2e28 * stakedAmount + totalSRare ** 2) - totalSRare) * _sqrt(stakedAmount)) / 1e13); 
  }

  /// @inheritdoc IRarityPool
  /// @dev Calculated based on percentage sRARE being unstaked.
  function calculateSaleReturn(
    uint256 _totalSRareByUser,
    uint256 _totalRareStakedByUser,
    uint256 _unstakeAmount
  ) public pure returns (uint256) {
    return ((_unstakeAmount * 100 * _totalRareStakedByUser) / _totalSRareByUser) / 100;
  }

  /// @inheritdoc IRarityPool
  function getAllTimeRewards() external view returns (uint256) {
    return sumOfAllRewards;
  }

  /// @inheritdoc IRarityPool
  function getCreationTime() external view returns (uint256) {
    return periodStart;
  }

  /// @inheritdoc IRarityPool
  function getLastSnapshotTimestamp() external view returns (uint256) {
    return lastSnapshotTimestamp;
  }

  /// @inheritdoc IRarityPool
  function getSumOfAllClaimed() external view returns (uint256) {
    return sumOfAllClaimed;
  }

  /// @inheritdoc IRarityPool
  function getStakingRegistry() public view returns (address) {
    return address(stakingRegistry);
  }


  /*//////////////////////////////////////////////////////////////////////////
                          Internal Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev Transfer function for moving synthetic tokens.
  function _transfer(address from, address to, uint256 amount) internal virtual override {
    if (msg.sender != address(this)) revert IRarityPool.Unauthorized();
    super._transfer(from, to, amount);
  }

  /// @dev Query rewards for this user this round.
  /// @param _user Address of the user to get rewards.
  /// @return uint256 Amount of $RARE tokens rewarded this round.
  function _getRewardsForUserForRound(
    address _user,
    uint256 _round,
    uint256 _currentSnapshotId
  ) internal view returns (uint256) {
    // If current round is greater that the snapshot ID, there is no snapshot to use so grab current
    uint256 totalSRareSupply = _round > _currentSnapshotId ? totalSupply() : totalSupplyAt(_round);

    // If there is no SRARE supply, return 0
    if (totalSRareSupply == 0) return 0;

    // If current round is greater that the snapshot ID, there is no snapshot to use so grab current
    uint256 senderBalance = _round > _currentSnapshotId ? balanceOf(_user) : balanceOfAt(_user, _round);

    // Here we multiply by 1e25 to pad zeroes for division
    return ((senderBalance * 1e25 * getRoundRewards(_round)) / totalSRareSupply) / 1e25;
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Internal Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @dev based on https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
  function _sqrt(uint256 x) internal pure returns (uint256 z) {
    assembly {
      // This segment is to get a reasonable initial estimate for the Babylonian method.
      // If the initial estimate is bad, the number of correct bits increases ~linearly
      // each iteration instead of ~quadratically.
      // The idea is to get z*z*y within a small factor of x.
      // More iterations here gets y in a tighter range. Currently, we will have
      // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
      // between y and y+1 is small. If x < 256 this is not possible, but those cases
      // are easy enough to verify exhaustively.
      z := 181 // The 'correct' value is 1, but this saves a multiply later
      let y := x
      // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
      // this is to ensure that if x >= 256, then y >= 256.
      if iszero(lt(y, 0x10000000000000000000000000000000000)) {
        y := shr(128, y)
        z := shl(64, z)
      }
      if iszero(lt(y, 0x1000000000000000000)) {
        y := shr(64, y)
        z := shl(32, z)
      }
      if iszero(lt(y, 0x10000000000)) {
        y := shr(32, y)
        z := shl(16, z)
      }
      if iszero(lt(y, 0x1000000)) {
        y := shr(16, y)
        z := shl(8, z)
      }
      // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
      // and either y >= 256, or x < 256.
      // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
      // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

      // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
      // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
      z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

      // Run the Babylonian method seven times. This should be enough given initial estimate.
      // Possibly with a quadratic/cubic polynomial above we could get 4-6.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
      // If x+1 is a perfect square, the Babylonian method cycles between
      // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
      // The solmate implementation assigns zRoundDown := div(x, z) first, but
      // since this case is rare, we choose to save gas on the assignment and
      // repeat division in the rare case.
      // If you don't care whether floor or ceil is returned, you can skip this.
      if lt(div(x, z), z) {
        z := div(x, z)
      }
    }
  }
}

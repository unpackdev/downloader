// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Bridge.sol";
import "./MyPausableUpgradeable.sol";
import "./console.sol";

/**
 * @title BridgeChefV1
 * This contract creates and manages token farms for the cross-chain bridge
 * It assigns a multiplier to each farm and distributes newly minted bridge tokens according to these multipliers
 */
contract BridgeChefV1 is MyPausableUpgradeable {
  using SafeERC20 for IERC20;

  /// Info of each deposit a user makes into a farm
  struct DepositInfo {
    uint256 amount; // How many LP tokens the user has locked in this deposit
    int256 rewardDebt; // the amount of undistributed rewards this deposit is not eligible for
  }

  // Info of each farm
  struct FarmInfo {
    uint256 farmMultiplier; // determines how many bridge tokens are assigned to this farm with each block
    uint256 lastRewardBlock; // Last block number in which bridge token rewards were calculated
    uint256 accBridgePerShare; // Accumulated bridge tokens per share
    address lpToken; // the address of the liquidity provider token that is needed to participate in this farm
  }

  // factor used to limit rounding errors
  uint256 private constant _ROUNDING_PRECISION = 1e12;

  // The ERC20 Bridge token contract
  Bridge public bridgeToken;

  // Dev address
  address public devAddr;

  // the percentage of minted Bridge tokens that is rewarded to devAddr
  uint64 public devRewardPercentage;

  // address of the staking pool
  address public stakingAddr;

  // the percentage of minted Bridge that is rewarded to the staking pool
  uint64 public stakingPercentage;

  // ROLES
  bytes32 public constant FARM_ADMIN_ROLE = keccak256('FARM_ADMIN_ROLE'); // can add, set and change farms
  bytes32 public constant REWARD_ADMIN_ROLE = keccak256('REWARD_ADMIN_ROLE'); // can change reward parameters around user rewards
  bytes32 public constant DISTRIBUTION_ADMIN_ROLE = keccak256('DISTRIBUTION_ADMIN_ROLE'); // can change dev and dev rewards as well as share and address of staking farm

  // Bridge tokens created per block
  uint256 public bridgePerBlock;

  // Info of each farm
  FarmInfo[] public farmInfo;

  /// Collection that holds all LP token contract addresses (one for each farm)
  IERC20[] public lpToken;

  /// Info of each user that stakes LP tokens
  /// (farmId => user address => DepositInfo)
  mapping(uint256 => mapping(address => DepositInfo)) public depositInfo;

  // Sum of all multipliers (required to calculate Bridge token share per farm)
  uint256 public sumOfFarmMultiplier;

  // the average amount of blocks mined per day. Used to calculate block limits from days
  uint256 public blocksPerDay;

  /// Info if a farm was already created for a specific LP token
  /// LP token address => true/false (true if for this LP token a pool already exists)
  mapping(address => bool) public usedLpTokens;

  event FarmAdded(uint256 indexed farmId, uint256 farmMultiplier, IERC20 indexed lpToken);

  event FarmMultiplierChanged(uint256 indexed farmId, uint256 farmMultiplier);

  event FarmUpdated(uint256 indexed farmId, uint256 lastRewardBlock, uint256 lpSupply, uint256 accBridgePerShare);

  event DepositAdded(address indexed user, uint256 indexed farmId, uint256 amount);

  event FundsWithdrawn(address indexed user, uint256 indexed farmId, uint256 amount);

  event RewardsHarvested(address indexed user, uint256 indexed farmId, uint256 amount);

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   *
   * @dev can only be called once after deployment of the contract
   * @param _bridgeToken The actual Bridge token
   * @param _devAddr The dev address to receive bridge token rewards
   * @param _devRewardPercent the percentage of minted Bridge tokens that go to the developer
   * @param _stakingPool address of the staking pool that receives part of the minted Bridge tokens
   * @param _stakingPercent the percentage of minted Bridge tokens that goes into the staking pool
   * @param _bridgePerBlock the amount of Bridge token minted per block
   */
  function initialize(
    Bridge _bridgeToken,
    address _devAddr,
    uint64 _devRewardPercent,
    address _stakingPool,
    uint64 _stakingPercent,
    uint256 _bridgePerBlock
  ) external initializer {
    require(_devAddr != address(0), 'BridgeChefV1: dev address cannot be 0');
    require(_stakingPool != address(0), 'BridgeChefV1: staking address cannot be 0');

    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    bridgeToken = _bridgeToken;
    devAddr = _devAddr;
    devRewardPercentage = _devRewardPercent;
    stakingAddr = _stakingPool;
    stakingPercentage = _stakingPercent;
    bridgePerBlock = _bridgePerBlock;
    blocksPerDay = 28800;
  }

  /**
   * @notice Adds a new liquidity provider (LP) farm
   *
   * @dev Can only be called by the FARM_ADMIN_ROLE
   * @param _farmMultiplier the multiplier that this farm gets (value 100 = multiplier 1, value 300 = multiplier 3, value 0 will deactivate the farm entirely)
   * @param _lpToken the LP token for this farm
   * @param _withUpdate should you update all other farm? You probably should
   * @dev emits event FarmAdded after successful farm creation
   */
  function add(
    uint256 _farmMultiplier,
    IERC20 _lpToken,
    bool _withUpdate
  ) external whenNotPaused nonReentrant {
    // check permission and input parameter
    require(hasRole(FARM_ADMIN_ROLE, _msgSender()), 'BridgeChefV1: must have FARM_ADMIN_ROLE to execute this function');
    require(address(_lpToken) != address(0), 'BridgeChefV1: LP token address cannot be 0');
    require(!usedLpTokens[address(_lpToken)], 'BridgeChefV1: farm already exists for this LP token');

    // run mass farm update if flag was set to true
    if (_withUpdate) {
      massUpdateFarms();
    }

    // Add multiplier to sumOfFarmMultiplier so bridge distribution ratio can be correctly calculated
    sumOfFarmMultiplier = sumOfFarmMultiplier + _farmMultiplier;

    // add LP token to list of LP tokens
    lpToken.push(_lpToken);

    // add LP token to list of used LP tokens
    usedLpTokens[address(_lpToken)] = true;

    // create a new LP farm and save it in the list of farms (farmInfo)
    farmInfo.push(
      FarmInfo({
        farmMultiplier: _farmMultiplier,
        lastRewardBlock: block.number,
        accBridgePerShare: 0,
        lpToken: address(_lpToken)
      })
    );

    // LP farm successfully created, emit event
    emit FarmAdded(farmInfo.length - 1, _farmMultiplier, _lpToken);
  }

  /**
   * @notice Updates the given farm's multiplier (that determines how many bridge token will be assigned to this farm on each block)
   *
   * @dev Can only be called by the FARM_ADMIN_ROLE
   * @dev setting _farmMultiplier to 0 will effectively deactivate the farm (no bridge rewards) whereas setting it to 1 will be the standard setting
   * @param _farmMultiplier the multiplier that this farm gets
   * @param _withUpdate if set to true, all other reward farms will be updated, too (choose yes, if possible)
   * @dev emits event FarmMultiplierChanged after successful update
   */
  function updateFarmMultiplier(
    uint256 farmId,
    uint256 _farmMultiplier,
    bool _withUpdate
  ) external {
    // check input parameters
    require(hasRole(FARM_ADMIN_ROLE, _msgSender()), 'BridgeChefV1: must have FARM_ADMIN_ROLE to execute this function');
    require(farmId < farmInfo.length, 'BridgeChefV1: a farm with this ID does not exist');

    // run mass farm update if flag was set to true
    if (_withUpdate) {
      massUpdateFarms();
    }

    // update the variable that sums up all multipliers (remove old multiplier, add new multiplier)
    sumOfFarmMultiplier = sumOfFarmMultiplier - farmInfo[farmId].farmMultiplier + _farmMultiplier;

    // update farm info
    farmInfo[farmId].farmMultiplier = _farmMultiplier;

    // farm updated successfully, emit event
    emit FarmMultiplierChanged(farmId, _farmMultiplier);
  }

  /**
   * @notice Checks how many bridge tokens are ready for harvesting for a given user in the given reward farm
   *
   * @param farmId The index of the farm
   * @param user the address of the user to query the info for
   * @return returns the amount of bridge tokens that are ready for harvesting
   */
  function bridgeTokensReadyToHarvest(uint256 farmId, address user) external view returns (uint256) {
    //check input parameters
    require(farmId < farmInfo.length, 'BridgeChefV1: a farm with this ID does not exist');

    // get farm info
    FarmInfo memory farm = farmInfo[farmId];

    // get user deposit info
    DepositInfo memory userDeposit = depositInfo[farmId][user];

    if (userDeposit.amount == 0) {
      return 0;
    }

    // get the farm's accumulated reward per share
    uint256 accBridgePerShare = farm.accBridgePerShare;

    uint256 lpSupply = IERC20(farm.lpToken).balanceOf(address(this));

    // check if farm has funds and if new rewards have been accumulated since last reward
    if (block.number > farm.lastRewardBlock && lpSupply != 0) {
      // calculate how many blocks have passed since last reward
      uint256 blocks = block.number - farm.lastRewardBlock;

      // calculate how many bridge tokens are pending for this farm
      // (=>> blocks * bridgePerBlock * farm multiplier / sumOfFarmMultipliers)
      uint256 bridgeReward = (blocks * bridgePerBlock * farm.farmMultiplier) / sumOfFarmMultiplier;

      // calculate how many bridge tokens will be assigned to each share in the farm
      accBridgePerShare = accBridgePerShare + (bridgeReward * _ROUNDING_PRECISION) / lpSupply;
    }

    // return the calculated amount of bridge tokens that are pending for the shareholder
    return uint256(int256((userDeposit.amount * accBridgePerShare) / _ROUNDING_PRECISION) - userDeposit.rewardDebt);
  }

  /**
   * @notice Update reward variables for all available reward farms
   *
   * @dev be careful of gas spending! If gas fees are too high, use overloaded method with to/from parameter
   * @dev emits event FarmUpdated for each successfully updated reward farm
   */
  function massUpdateFarms() public whenNotPaused {
    massUpdateFarms(0, farmInfo.length - 1);
  }

  /**
   * @notice Update reward variables for the given range of reward farms
   *
   * @param from the starting index for the mass update (first element: 0)
   * @param to the ending index for the mass update (if you want to update the first 5 reward farms, the 'to' value should be 4)
   * @dev emits event FarmUpdated for each successfully updated reward farm
   */
  function massUpdateFarms(uint256 from, uint256 to) public whenNotPaused {
    require(from <= to, "BridgeChefV1: 'from' value must be lower than 'to' value");
    require(to < farmInfo.length, "BridgeChefV1: 'to' value must be lower than 'farmInfo.length'");
    for (uint256 farmId = from; farmId <= to; ++farmId) {
      updateFarm(farmId);
    }
  }

  /**
   * @notice Update reward variables for the given reward farm
   *
   * @param farmId The index of the farm
   * @return farm returns the updated liquidity farm information
   * @dev emits event FarmUpdated after successful update
   */
  function updateFarm(uint256 farmId) public whenNotPaused returns (FarmInfo memory) {
    require(farmId < farmInfo.length, 'BridgeChefV1: invalid farm ID provided');
    FarmInfo storage farm = farmInfo[farmId];

    //check if rewards have been accrued since last reward calculation
    if (block.number <= farm.lastRewardBlock) {
      return farm;
    }

    uint256 lpSupply = IERC20(farm.lpToken).balanceOf(address(this));

    // check if farm is funded with LP tokens
    if (lpSupply <= 0) {
      // update lastRewardblock with current block number
      farm.lastRewardBlock = block.number;
      emit FarmUpdated(farmId, farm.lastRewardBlock, lpSupply, farm.accBridgePerShare);
      return farm;
    }

    // calculate how many blocks have passed since last reward calculation
    uint256 blocks = block.number - farm.lastRewardBlock;

    // calculate the amount of bridge tokens this farm has accrued since last reward calculation
    // (=>> blocks * bridgePerBlock * farm multiplier / sumOfFarmMultipliers)
    uint256 bridgeReward = (blocks * bridgePerBlock * farm.farmMultiplier) / sumOfFarmMultiplier;

    // mint bridge tokens to developer account (if set), staking pool (if set) and to this contract
    bridgeToken.mint(address(this), bridgeReward);
    bridgeToken.mint(devAddr, (bridgeReward * devRewardPercentage) / 100);
    bridgeToken.mint(stakingAddr, (bridgeReward * stakingPercentage) / 100);

    // update accumulatedBridgePerShare calculation in farm
    farm.accBridgePerShare = farm.accBridgePerShare + (bridgeReward * _ROUNDING_PRECISION) / lpSupply;

    // set lastRewardBlock to current block number
    farm.lastRewardBlock = block.number;

    // farm updated, emit event
    emit FarmUpdated(farmId, farm.lastRewardBlock, lpSupply, farm.accBridgePerShare);

    return farm;
  }

  /**
   * @notice Deposits liquidity provider (LP) tokens to the given reward farm for the user to start earning bridge tokens
   *
   * @param farmId the ID of the liquidity farm
   * @param amount LP token amount to be deposited
   *
   * @dev emits event DepositAdded after the deposit was successfully added
   */
  function deposit(uint256 farmId, uint256 amount) external whenNotPaused nonReentrant {
    // run some input parameter and data checks
    require(farmId < farmInfo.length, 'BridgeChefV1: a farm with this ID does not exist');
    require(amount != 0, 'BridgeChefV1: deposit amount cannot be 0');

    // get farm info
    FarmInfo storage farm = farmInfo[farmId];

    // update the farm to have a clean start for the new deposit
    updateFarm(farmId);

    // create or update a deposit and persist it
    DepositInfo storage userDeposit = depositInfo[farmId][_msgSender()];
    userDeposit.amount = userDeposit.amount + amount;
    userDeposit.rewardDebt = userDeposit.rewardDebt + int256((amount * farm.accBridgePerShare) / _ROUNDING_PRECISION);

    // Interactions - transfer LP tokens from user to this smart contract
    lpToken[farmId].safeTransferFrom(_msgSender(), address(this), amount);

    // deposit successfully processed, emit event
    emit DepositAdded(_msgSender(), farmId, amount);
  }

  /**
   * @notice Harvests bridge rewards and sends them to the caller of this function
   *
   * @param farmId the ID of the liquidity farm
   *
   * @dev emits event RewardsHarvested after the rewards have been transferred to the caller
   */
  function harvest(uint256 farmId) external whenNotPaused nonReentrant {
    // check if farm exists
    require(farmId < farmInfo.length, 'BridgeChefV1: a farm with this ID does not exist');

    // update farm calculations
    FarmInfo memory farm = updateFarm(farmId);

    // get deposit information
    DepositInfo storage userDeposit = depositInfo[farmId][_msgSender()];

    // check if user/deposit exists
    require(userDeposit.amount != 0, 'BridgeChefV1: deposit/user not found');

    // calculate the accumulated reward amount
    int256 accumulatedBridgeTokens = int256((userDeposit.amount * farm.accBridgePerShare) / _ROUNDING_PRECISION);
    uint256 _pendingBridgeToken = uint256(accumulatedBridgeTokens - userDeposit.rewardDebt);

    // check if any bridge tokens are ready for harvesting
    require(_pendingBridgeToken > 0, 'BridgeChefV1: no funds available for harvesting');

    // Effects - update rewardDebt with current harvest amount
    userDeposit.rewardDebt = accumulatedBridgeTokens;

    // Interactions - transfer bridge tokens to _msgSender()
    safeBridgeTransfer(_msgSender(), _pendingBridgeToken);

    // harvest successful, emit event
    emit RewardsHarvested(_msgSender(), farmId, _pendingBridgeToken);
  }

  /**
   * @notice Withdraws liquidity provider (LP) tokens from the given reward farm
   *
   * @param farmId the ID of the liquidity farm
   * @param amount LP token amount to withdraw
   *
   * @dev emits event FundsWithdrawn after successful withdrawal
   */
  function withdraw(uint256 farmId, uint256 amount) external whenNotPaused nonReentrant {
    // get deposit info
    DepositInfo storage userDeposit = depositInfo[farmId][_msgSender()];

    // check input parameters
    require(farmId < farmInfo.length, 'BridgeChefV1: a farm with this ID does not exist');
    require(amount > 0, 'BridgeChefV1: withdrawal amount cannot be 0');
    require(userDeposit.amount != 0, 'BridgeChefV1: deposit/user not found');

    // update farm reward calculations
    FarmInfo memory farm = updateFarm(farmId);

    // calculate the accumulated reward amount
    int256 accumulatedBridgeTokens = int256((userDeposit.amount * farm.accBridgePerShare) / _ROUNDING_PRECISION);
    uint256 _pendingBridgeToken = uint256(accumulatedBridgeTokens - userDeposit.rewardDebt);

    // update reward debt to reflect that funds have been withdrawn
    userDeposit.rewardDebt = userDeposit.rewardDebt - int256((amount * farm.accBridgePerShare) / _ROUNDING_PRECISION);

    // subtract the withdrawal amount from the deposit
    userDeposit.amount = userDeposit.amount - amount;

    // Interactions - transfer bridge tokens to _msgSender()
    safeBridgeTransfer(_msgSender(), _pendingBridgeToken);

    // Interactions
    // transfer LP token back to user
    lpToken[farmId].safeTransfer(_msgSender(), amount);

    // harvest successful, emit event
    emit RewardsHarvested(_msgSender(), farmId, _pendingBridgeToken);
    // withdrawal successful, emit event
    emit FundsWithdrawn(_msgSender(), farmId, amount);
  }

  /**
   * @notice Helper function to ensure that bridge token transfers work even for cases with rounding precision errors
   *
   * @param _to the account to transfer Bridge token to
   * @param amount the amount of LP tokens to transfer
   */
  function safeBridgeTransfer(address _to, uint256 amount) internal whenNotPaused {
    // get this contract's current balance of bridge token
    uint256 balance = bridgeToken.balanceOf(address(this));

    // check if amount to be sent is greater than available balance
    if (amount > balance) {
      // send current balance
      bridgeToken.transfer(_to, balance);
    } else {
      // send exact amount
      bridgeToken.transfer(_to, amount);
    }
  }

  /**
   * @notice Sets the staking pool address (which receives parts of the bridge rewards, if activated)
   *
   * @dev can only be called by DISTRIBUTION_ADMIN_ROLE
   * @param _stakingAddr the address of the staking pool
   */
  function setStakingAddr(address _stakingAddr) external {
    require(
      hasRole(DISTRIBUTION_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have DISTRIBUTION_ADMIN_ROLE to execute this function'
    );
    require(_stakingAddr != address(0), 'BridgeChefV1: invalid staking pool address provided');
    stakingAddr = _stakingAddr;
  }

  /**
   * @notice Sets the staking reward percentage for the staking pool
   *
   * @dev can only be called by DISTRIBUTION_ADMIN_ROLE
   * @param percentage the percentage of the staking pool reward (1 = 1%, 25 = 25%)
   */
  function setStakingReward(uint64 percentage) external {
    require(
      hasRole(DISTRIBUTION_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have DISTRIBUTION_ADMIN_ROLE to execute this function'
    );
    stakingPercentage = percentage;
  }

  /**
   * @notice Sets the developer address (which receives parts of the bridge rewards, if activated)
   *
   * @dev can only be called by DISTRIBUTION_ADMIN_ROLE
   * @param _devAddr the address of the developer account
   */
  function setDevAddress(address _devAddr) external {
    require(
      hasRole(DISTRIBUTION_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have DISTRIBUTION_ADMIN_ROLE to execute this function'
    );
    require(_devAddr != address(0), 'BridgeChefV1: invalid developer address provided');
    devAddr = _devAddr;
  }

  /**
   * @notice Sets the reward percentage for the developer
   *
   * @dev can only be called by DISTRIBUTION_ADMIN_ROLE
   * @param percentage the percentage of the developer reward (1 = 1%, 25 = 25%)
   */
  function setDevRewardPercentage(uint64 percentage) external {
    require(
      hasRole(DISTRIBUTION_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have DISTRIBUTION_ADMIN_ROLE to execute this function'
    );
    devRewardPercentage = percentage;
  }

  /**
   * @notice Sets the amount of blocks (minting new Bridge token) per day
   *
   * @dev can only be called by REWARD_ADMIN_ROLE
   * @param _blocksPerDay the amount of blocks per day.. duh
   */
  function setBlocksPerDay(uint256 _blocksPerDay) external {
    require(
      hasRole(REWARD_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have REWARD_ADMIN_ROLE to execute this function'
    );
    require(_blocksPerDay > 0, 'BridgeChefV1: blocks per day cannot be 0');
    blocksPerDay = _blocksPerDay;
  }

  /**
   * @notice Sets amount of bridge tokens that are minted per block
   *
   * @dev can only be called by REWARD_ADMIN_ROLE
   * @param amount the amount of bridge tokens that are minted by this contract per block
   */
  function setBridgePerBlock(uint256 amount) external {
    require(
      hasRole(REWARD_ADMIN_ROLE, _msgSender()),
      'BridgeChefV1: must have REWARD_ADMIN_ROLE to execute this function'
    );
    bridgePerBlock = amount;
  }
}

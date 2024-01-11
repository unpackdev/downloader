// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/**
 * @title LPStaking contract
 * @author Ajitesh Mishra
 * @notice This contract will store and manage staking at APR defined by owner
 * @dev Store, calculate, collect and transefer stakes and rewards to end user
 */
contract LPStaking is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // Lib for uints
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _depositIds;
    // Sec in a year

    uint256 private APRTime; // = 365 days (For testing it can be updated to shorter time.)
    address public onlyaddress;
    IERC20Upgradeable public WETH; // WETH Contract

    // Structure to store StakeHoders details
    struct stakeDetails {
        uint256 depositId; //deposit id
        uint256 stake; // Total amount staked by the user for perticular pool
        uint256 reward; // Total unclaimed reward calculated at lastRewardCalculated
        uint256 APR; // APR at which the amount was staked
        uint256 period; // vested for period
        uint256 lastRewardCalculated; // time when user staked
        uint256 poolId; //poolId
        uint256 vestedFor; // months
    }

    //interest rate
    struct interestRate {
        uint256 period;
        uint256 APR;
    }

    //poolid=>period=>APR
    mapping(uint256 => mapping(uint256 => uint256)) public vestingAPRPerPool;
    /** mapping to store current status for stakeHolder
     * Explaination:
     *  {
     *      Staker: {
     *           Pool: staking details
     *      }
     *  }
     */

    mapping(address => bool) public tokenPools;
    mapping(address => mapping(uint256 => stakeDetails)) public deposits;
    mapping(address => uint256[]) public userDepositMap;
    mapping(uint256 => stakeDetails) public depositDetails;

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event RewardClaimed(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event WETHDeposit(address indexed user, uint256 amount);
    event WETHWithdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 feeReward);

    // Structure to store the pool's information
    struct stakingPool {
        address token; // Address of staking token
        address reward; // Address of reward token
        uint256 tvl; // Total value currently locked in this pool
        uint256 totalAllotedReward; // Total award transfered to this contract by admin for reward.
        uint256 totalClaimedReward; // Total reward claimed in this pool
    }

    struct periodPool {
        uint256 tvl;
        uint256 totalAllotedFeeReward;
    }

    // List of pools created by admin
    stakingPool[] public pools;

    //pool period map period=>tvl
    mapping(uint256 => periodPool) public periodPoolMap;

    //mapping(uint => periodPool) periodMaketFee;
    uint256[] periods;

    //Bool for staking and reward calculation paused
    bool public isPaused;
    uint256 public pausedTimestamp;
    uint256 public periodSum; //sum of all periods
    uint256 public constant PRECISION_FACTOR = 10**18;
    /**
     * @dev Modifier to check if pool exists
     * @param _poolId Pools's ID
     */
    modifier poolExists(uint256 _poolId) {
        require(_poolId < pools.length, "Staking: Pool doesn't exists");
        _;
    }

    modifier onlyAddress() {
        require(_msgSender() == onlyaddress, "invalid access");
        _;
    }

    /**
     * @notice This method will be called once only by proxy contract to init.
     */
    function initialize(address _feeToken, uint256[] memory _periods) external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        periods = _periods;
        WETH = IERC20Upgradeable(_feeToken);
        APRTime = 365 days;
        setPeriodSum(_periods);
    }

    modifier isUniqueTokenPool(address _token) {
        require(!tokenPools[_token], "Add : token pool already exits");
        _;
    }

    function setOnlyAddress(address _only) external onlyOwner {
        onlyaddress = _only;
    }

    /**
     * @dev This function is used to calculate sum of periods
     */

    function setPeriodSum(uint256[] memory _periods) internal {
        periodSum = 0;
        for (uint256 i = 0; i < _periods.length; i++) {
            periodSum += _periods[i] == 0 ? 1 : _periods[i];
        }
    }

    /**
     * @dev This function will create new pool, access type is onlyOwner
     * @notice This Function will create new pool with the token address,\
       reward address and the APR percentage.
     * @param _token Staking token address for this pool. 
     * @param _reward Staking reward token address for this pool
     * @param _periodRates APR percentage * 1000 for this pool.
     */
    function addPool(
        address _token,
        address _reward,
        interestRate[] memory _periodRates
    ) public onlyOwner isUniqueTokenPool(_token) {
        tokenPools[_token] = true;
        uint256 index = pools.length > 0 ? pools.length - 1 : pools.length;

        // Add pool to contract
        for (uint256 i; i < _periodRates.length; i++) {
            vestingAPRPerPool[index][_periodRates[i].period] = _periodRates[i].APR;
        }
        pools.push(stakingPool(_token, _reward, 0, 0, 0));
    }

    /**
     * @dev This function allows owner to pause contract.
     */
    function PauseStaking() public onlyOwner {
        require(!isPaused, "Already Paused");
        isPaused = true;
        pausedTimestamp = block.timestamp;
    }

    /**
     * @dev This function allows owner to resume contract.
     */
    function ResumeStaking() public onlyOwner {
        require(isPaused, "Already Operational");
        isPaused = false;
        pausedTimestamp = block.timestamp;
    }

    /**
     * @dev This funtion will return the length of pools\
        which will be used to loop and get pool details.
     * @notice Get the length of pools and use it to loop for index.
     * @return Length of pool.
     */
    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    /**
     * @dev This function allows owner to update APR for specific pool.
     * @notice Let's you update the APR for this pool if you're current owner.
     * @param _poolId pool's Id in which you want to update the APR.
     * @param _periodRates New APR percentage * 1000.
     */
    function updateAPR(uint256 _poolId, interestRate[] memory _periodRates) public onlyOwner poolExists(_poolId) {
        for (uint256 i; i < _periodRates.length; i++) {
            vestingAPRPerPool[_poolId][_periodRates[i].period] = _periodRates[i].APR;
        }
    }

    function getAPR(uint256 _poolId, uint256 _period) public view returns (uint256) {
        return vestingAPRPerPool[_poolId][_period];
    }

    /**
     * @dev This funciton allows owner to withdraw allotted reward amount from this contract.
     * @notice Let's you withdraw reward fund in this contract.
     * @param _poolId pool's Id in which you want to withdraw this reward.
     * @param amount amount to be withdraw from contract to owner's wallet.
     */
    function withdrawRewardfromPool(uint256 _poolId, uint256 amount) public onlyOwner poolExists(_poolId) {
        // Reward contract object.
        IERC20Upgradeable rewardToken = IERC20Upgradeable(pools[_poolId].reward);

        // Check if amount is allowed to spend the token
        require(
            pools[_poolId].totalAllotedReward >= amount,
            "Staking: amount Must be less than or equal to available rewards"
        );

        // Transfer the token to contract
        rewardToken.transfer(msg.sender, amount);

        // Update the pool's stats
        pools[_poolId].totalAllotedReward -= amount;
    }

    /**
     * @dev This funciton allows owner to add more reward amount to  this contract.
     * @notice Let's you allot more reward fund in this contract.
     * @param _poolId pool's Id in which you want to add this reward.
     * @param amount amount to be transfered from owner's wallet to this contract.
     */
    function addRewardToPool(uint256 _poolId, uint256 amount) public onlyOwner poolExists(_poolId) {
        // Reward contract object.
        IERC20Upgradeable rewardToken = IERC20Upgradeable(pools[_poolId].reward);

        // Check if amount is allowed to spend the token
        require(rewardToken.allowance(msg.sender, address(this)) >= amount, "Staking: Must allow Spending");

        // Transfer the token to contract
        rewardToken.transferFrom(msg.sender, address(this), amount);

        // Update the pool's stats
        pools[_poolId].totalAllotedReward += amount;
    }

    /**
     * @notice Receive WETH Fee Deposit only admin
     *
     * @param amount to deposit
     */

    function receiveWETHFee(uint256 amount) external onlyAddress nonReentrant {
        require(amount > 0, "Collect Fee: Amount must be > 0");
        WETH.transferFrom(_msgSender(), address(this), amount);

        for (uint256 i = 0; i < periods.length; i++) {
            periodPoolMap[periods[i]].totalAllotedFeeReward += periods[i] == 0
                ? (((1 * PRECISION_FACTOR) / periodSum) * amount) / PRECISION_FACTOR
                : (((periods[i] * PRECISION_FACTOR) / periodSum) * amount) / PRECISION_FACTOR;
        }
        emit WETHDeposit(_msgSender(), amount);
    }

    /**
     * @dev This function is used to withdraw WETH from contract from Admin only
     */

    function AdminWETHWithdraw() external onlyOwner nonReentrant {
        uint256 accMarketFee = WETH.balanceOf(address(this));
        WETH.transferFrom(address(this), _msgSender(), accMarketFee);
        emit WETHWithdraw(_msgSender(), accMarketFee);
    }

    /**
     * @dev This function is used to calculate current reward for stakeHolder
     * @param _stakeHolder The address of stakeHolder to calculate reward till current block
     * @return reward calculated till current block
     */
    function _calculateReward(
        address _stakeHolder,
        uint256 _dId,
        bool isProrata
    ) internal view returns (uint256 reward) {
        stakeDetails memory stakeDetail = _stakeHolder != address(0)
            ? deposits[_stakeHolder][_dId]
            : depositDetails[_dId];

        if (stakeDetail.stake > 0) {
            // Without safemath formula for explanation
            // reward = (
            //     (stakeDetail.stake * stakeDetails.APR * (block.timestamp - stakeDetail.lastRewardCalculated)) /
            //     (APRTime * 100 * 1000)
            // );
            if (isPaused) {
                if (stakeDetail.lastRewardCalculated > pausedTimestamp) {
                    reward = 0;
                } else {
                    reward = stakeDetail
                        .stake
                        .mul(stakeDetail.APR)
                        .mul(pausedTimestamp.sub(stakeDetail.lastRewardCalculated))
                        .div(APRTime.mul(100).mul(1000));
                }
            } else {
                uint256 APR = isProrata ? getAPR(stakeDetail.poolId, 0) : stakeDetail.APR;
                reward = stakeDetail.stake.mul(APR).mul(block.timestamp.sub(stakeDetail.lastRewardCalculated)).div(
                    APRTime.mul(100).mul(1000)
                );
            }
        } else {
            reward = 0;
        }
    }

    /**
     * @dev This function is used to calculate Total reward for stakeHolder for pool
     * @param _stakeHolder The address of stakeHolder to calculate Total reward
     * @param _dId deposit id for reward calculation
     * @param isProrata to calculate on prorata basis
     * @return reward total reward
     */
    function calculateReward(
        address _stakeHolder,
        uint256 _dId,
        bool isProrata
    ) public view returns (uint256 reward) {
        stakeDetails memory stakeDetail = deposits[_stakeHolder][_dId];
        reward = stakeDetail.reward + _calculateReward(_stakeHolder, _dId, isProrata);
    }

    /**
     * @dev Allows user to stake the amount the pool. Calculate the old reward\
       and updates the reward, staked amount and current APR.
     * @notice This function will update your staked amount.
     * @param _poolId The pool in which user wants to stake.
     * @param amount The amount user wants to add into his stake.
     */
    function stake(
        uint256 _poolId,
        uint256 amount,
        uint256 _period
    ) external nonReentrant whenNotPaused poolExists(_poolId) returns (uint256) {
        require(!isPaused, "Staking is paused");
        require(amount > 0, "Invalid amount");
        require(getAPR(_poolId, _period) != 0, "Invalid staking period");

        IERC20Upgradeable token = IERC20Upgradeable(pools[_poolId].token);

        // Check if amount is allowed to spend the token
        require(token.allowance(msg.sender, address(this)) >= amount, "Staking: Must allow Spending");

        // Transfer the token to contract
        token.transferFrom(msg.sender, address(this), amount);

        _depositIds.increment();
        uint256 id = _depositIds.current();
        // Calculate the last reward
        uint256 uncalculatedReward = _calculateReward(msg.sender, id, true);

        // Update the stake details
        deposits[msg.sender][id].depositId = id;
        deposits[msg.sender][id].stake += amount;
        deposits[msg.sender][id].reward += uncalculatedReward;
        deposits[msg.sender][id].lastRewardCalculated = block.timestamp;
        deposits[msg.sender][id].APR = getAPR(_poolId, _period);
        deposits[msg.sender][id].period = block.timestamp + (_period * 30 days);
        deposits[msg.sender][id].poolId = _poolId;
        deposits[msg.sender][id].vestedFor = _period;
        userDepositMap[msg.sender].push(id);
        depositDetails[id] = deposits[msg.sender][id];
        // Update TVL
        pools[_poolId].tvl += amount;
        periodPoolMap[_period].tvl += amount;

        emit Staked(msg.sender, amount, _poolId, block.timestamp);
        return id;
    }

    modifier whenNotPaused() {
        require(!isPaused, "contract paused!");
        _;
    }

    /**
     * @dev Calculate the current reward and unstake the stake token, Transefer
     * it to sender and update reward to 0
     * @param _poolId Pool from which user want to claim the reward.
     * @param _dId deposit id for getting reward fot deposit.
     * @param isForceWithdraw bool flag for emergency withdraw.
     * @notice This function will transfer the reward earned till now and staked token amount.
     */
    function withdraw(
        uint256 _poolId,
        uint256 _dId,
        bool isForceWithdraw
    ) external nonReentrant whenNotPaused poolExists(_poolId) {
        stakeDetails memory details = deposits[msg.sender][_dId];
        bool check = isForceWithdraw ? true : block.timestamp > details.period;
        require(details.stake > 0, "Claim : Nothing to claim");
        require(check, "Claim : cannot withdraw before vesting period ends");
        // Calculate the last reward
        uint256 uncalculatedReward = _calculateReward(msg.sender, _dId, isForceWithdraw);

        uint256 reward = details.reward + uncalculatedReward;
        uint256 amount = details.stake;
        // Check for the allowance and transfer from the owners account
        require(
            pools[details.poolId].totalAllotedReward > reward,
            "Staking: Insufficient reward allowance from the Admin"
        );

        // Transfer the reward.
        IERC20Upgradeable rewardtoken = IERC20Upgradeable(pools[details.poolId].reward);
        rewardtoken.transfer(msg.sender, reward);

        // Send the unstaked amout to stakeHolder
        IERC20Upgradeable staketoken = IERC20Upgradeable(pools[details.poolId].token);
        staketoken.transfer(msg.sender, amount);

        if (!isForceWithdraw && periodPoolMap[details.vestedFor].totalAllotedFeeReward > 0) {
            //transfer marketFee reward
            harvestFee(msg.sender, _dId);
        }

        // Update pools stats
        pools[details.poolId].totalAllotedReward -= reward;
        pools[details.poolId].totalClaimedReward += reward;
        pools[details.poolId].tvl -= details.stake;

        periodPoolMap[details.vestedFor].tvl -= amount;

        // Update the stake details
        deposits[msg.sender][_dId].reward = 0;
        deposits[msg.sender][_dId].stake = 0;
        if (isPaused) {
            deposits[msg.sender][_dId].lastRewardCalculated = pausedTimestamp;
        } else {
            deposits[msg.sender][_dId].lastRewardCalculated = block.timestamp;
        }

        // Trigger the event
        emit RewardClaimed(msg.sender, reward, _poolId, block.timestamp);
    }

    /**
     * @dev Disburse users Depsoits Unclaimed marketfee reward
     * @param _user address of the user
     * @param _dId deposit id for harvest
     * @notice This function will give send user there unclaimed marketfee reward.
     */
    function harvestFee(address _user, uint256 _dId) internal {
        stakeDetails memory deposit = deposits[_user][_dId];
        require(deposit.stake > 0, "Harvest: Not a staker");

        uint256 rewardFee = getHavestAmount(_user, _dId);
        if (rewardFee == 0 || periodPoolMap[deposit.vestedFor].totalAllotedFeeReward <= 0) {
            return;
        }

        uint256 balance = WETH.balanceOf(address(this));

        if (balance == 0) {
            return;
        }
        periodPoolMap[deposit.vestedFor].totalAllotedFeeReward -= rewardFee;
        WETH.transferFrom(address(this), _user, rewardFee);
        emit Harvest(_user, rewardFee);
    }

    /**
     * @dev Calculates users deposits WETH market fee reward
     * @notice This function will give you total of unclaimed rewards till now.
     * @return reward Total unclaimed WETH reward till now for specific deposit Id
     */
    function getHavestAmount(address _user, uint256 _dId) public view returns (uint256) {
        stakeDetails memory deposit = deposits[_user][_dId];
        uint256 locktime = deposit.vestedFor;
        if (deposit.stake < 0 || periodPoolMap[locktime].totalAllotedFeeReward < 0) {
            return 0;
        }

        uint256 feeRewardPerSecond;
        if (locktime == 0) {
            feeRewardPerSecond = periodPoolMap[locktime].totalAllotedFeeReward / 60 / 60 / 24 / 30 / 1;
        } else {
            feeRewardPerSecond = periodPoolMap[locktime].totalAllotedFeeReward / 60 / 60 / 24 / 30 / locktime;
        }
        uint256 pendingReward = (block.timestamp - deposit.lastRewardCalculated) * feeRewardPerSecond;

        uint256 reward = ((deposit.stake * PRECISION_FACTOR) / periodPoolMap[locktime].tvl) * pendingReward;

        return reward / PRECISION_FACTOR;
    }

    function getDeposits(address _user) public view returns (stakeDetails[] memory) {
        stakeDetails[] memory details = new stakeDetails[](userDepositMap[_user].length);
        for (uint256 i = 0; i < userDepositMap[_user].length; i++) {
            stakeDetails memory deposit = deposits[_user][userDepositMap[_user][i]];
            if (deposit.stake > 0) {
                details[i] = deposit;
            }
        }
        return details;
    }

    /**
     * @dev Calculate and return total undelivered rewards till now.
     * @notice This function will give you total of unclaimed rewards till now.
     * @return _totalReward Total unclaimed reward till now.
     */

    function totalReward() public view returns (uint256 _totalReward) {
        uint256 sum = 0;
        for (uint256 i = 1; i <= _depositIds.current(); i++) {
            if (depositDetails[i].stake > 0) {
                sum += depositDetails[i].reward;
                sum += _calculateReward(address(0), depositDetails[i].depositId, false);
            }
        }
        _totalReward = sum;
    }

    /**
     * @dev Function to check if contract have suffecient reward allowance or not
     * @notice This function will return if it has sufficient fund for paying the reward
     * @param _poolId The pool for which you want to check reward availibility
     * @return True if have sufficient allowance for paying all the rewards
     */
    function haveSuffecientFundsForReward(uint256 _poolId) public view returns (bool) {
        return pools[_poolId].totalAllotedReward >= totalReward();
    }

    /**
     * @dev Function to get balance of this contract WETH market fee
     * @return uint balance of weth in wei
     */
    function getAccMarketFee() public view returns (uint256) {
        return WETH.balanceOf(address(this));
    }
}

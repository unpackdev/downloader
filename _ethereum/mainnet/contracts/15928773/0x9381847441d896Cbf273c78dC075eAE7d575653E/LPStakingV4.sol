//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IUNIV3POS.sol";

/**
 * @title LPStaking contract
 * @notice This contract will store and manage staking at APR defined by owner
 * @dev Store, calculate, collect and transefer stakes and rewards to end user
 */

contract LPStakingV4 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // Lib for uints
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ECDSAUpgradeable for bytes32;

    CountersUpgradeable.Counter private _depositIds;
    // Sec in a year

    uint256 public constant NAME_HASH = 0x243a5c0d09cac1591e8ab0a70b571b38c787ea888ff8daba2831e0f0654752f3;
    uint256 private APRTime; // = 365 days (For testing it can be updated to shorter time.)
    address public validator;
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
        uint256 NFTId; //token Id
        bool isDyanmic; // flag for dynamic APR
    }

    IUNIV3POS uniV3;

    //interest rate
    struct interestRate {
        uint256 period;
        uint256 APR;
        uint256 ETH;
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
    //poolid=>period=>Eth per day
    mapping(uint256 => mapping(uint256 => uint256)) public poolPeriodEth;
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
    event Staked(address indexed staker, uint256 amount, uint256 indexed depositId, uint256 timestamp);
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 reward,
        uint256 indexed depositId,
        uint256 timestamp
    );
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

    struct range {
        uint256 min;
        uint256 max;
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

    uint256 public constant PRECISION_FACTOR = 10**18;
    address public admin;
    mapping(uint256 => address[]) public poolPair;
    mapping(uint256 => mapping(uint256 => range)) public poolPeriodRange;
    mapping(uint256 => bool) internal claimed;

    /**
     * @dev Modifier to check if pool exists
     * @param _poolId Pools's ID
     */
    modifier poolExists(uint256 _poolId) {
        require(_poolId < pools.length, "Staking: Pool doesn't exists");
        _;
    }

    /**
     * @notice This method will be called once only by proxy contract to init.
     */
    function initialize() external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        APRTime = 365 days;
    }

    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        WETH = IERC20Upgradeable(_feeToken);
    }

    function setAdminAddress(address _admin) external onlyOwner {
        admin = _admin;
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
        address _stakeToken,
        address _reward,
        interestRate[] memory _periodRates,
        bool isDyanmic
    ) public onlyOwner {
        uint256 index = pools.length > 0 ? pools.length - 1 : pools.length;
        uint256 len = _periodRates.length;
        if (isDyanmic) {
            // Add pool to contract
            for (uint256 i; i < len; i++) {
                poolPeriodEth[index][_periodRates[i].period] = _periodRates[i].ETH;
            }
        } else {
            // Add pool to contract
            for (uint256 i; i < len; i++) {
                vestingAPRPerPool[index][_periodRates[i].period] = _periodRates[i].APR;
            }
        }
        uniV3 = IUNIV3POS(_token);
        poolPair[index] = [_stakeToken, _reward];
        pools.push(stakingPool(_token, _reward, 0, 0, 0));
    }

    function updatePool(
        uint256 poolId,
        address _token,
        address _stakeToken,
        address _reward,
        interestRate[] memory _periodRates,
        bool isDyanmic
    ) public onlyOwner {
        uint256 len = _periodRates.length;
        if (isDyanmic) {
            for (uint256 i; i < len; i++) {
                poolPeriodEth[poolId][_periodRates[i].period] = _periodRates[i].ETH;
            }
        } else {
            for (uint256 i; i < len; i++) {
                vestingAPRPerPool[poolId][_periodRates[i].period] = _periodRates[i].APR;
            }
        }
        uniV3 = IUNIV3POS(_token);
        delete poolPair[poolId];
        poolPair[poolId] = [_stakeToken, _reward];
        pools[poolId].token = _token;
        pools[poolId].reward = _reward;
    }

    function setPoolPair(
        uint256 _poolId,
        address _stake,
        address _reward
    ) external whenNotPaused onlyOwner {
        if (poolPairExit(_poolId)) {
            delete poolPair[_poolId];
            poolPair[_poolId] = [_stake, _reward];
        } else {
            poolPair[_poolId] = [_stake, _reward];
        }
    }

    function poolPairExit(uint256 _poolId) internal view returns (bool) {
        try this.poolPair(_poolId, 0) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @dev This function allows owner to pause contract.
     */
    function pauseStaking() public onlyOwner {
        require(!isPaused, "Already Paused");
        isPaused = true;
        pausedTimestamp = block.timestamp;
    }

    function setPoolPeriodRange(
        uint256 _poolId,
        uint256 period,
        uint256 min,
        uint256 max
    ) external onlyOwner {
        poolPeriodRange[_poolId][period] = range(min, max);
    }

    /**
     * @dev This function allows owner to resume contract.
     */
    function resumeStaking() public onlyOwner {
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
        uint256 len = _periodRates.length;
        for (uint256 i; i < len; i++) {
            vestingAPRPerPool[_poolId][_periodRates[i].period] = _periodRates[i].APR;
        }
    }

    /**
     * @dev This function allows owner to update APR for specific pool.
     * @notice Let's you update the APR for this pool if you're current owner.
     * @param _poolId pool's Id in which you want to update the APR.
     * @param _periodRates New APR percentage * 1000.
     */
    function updateETHOnPeriod(uint256 _poolId, interestRate[] memory _periodRates)
        public
        onlyOwner
        poolExists(_poolId)
    {
        uint256 len = _periodRates.length;

        for (uint256 i; i < len; i++) {
            poolPeriodEth[_poolId][_periodRates[i].period] = _periodRates[i].ETH;
        }
    }

    function getAPR(uint256 _poolId, uint256 _period) public view returns (uint256) {
        return vestingAPRPerPool[_poolId][_period];
    }

    function getDyanmicAPR(
        uint256 _poolId,
        uint256 _period,
        uint256 _ethUSD,
        uint256 _totalLpStaked
    ) public view returns (uint256) {
        uint256 ethPerDay = poolPeriodEth[_poolId][_period];
        uint256 apr = calculateDyanmicAPR(ethPerDay, _ethUSD, _totalLpStaked);
        uint256 min = poolPeriodRange[_poolId][_period].min;
        uint256 max = poolPeriodRange[_poolId][_period].max;
        if (apr < min) {
            apr = min;
        }
        if (apr > max) {
            apr = max;
        }
        return apr;
    }

    function calculateDyanmicAPR(
        uint256 _ethPerDay,
        uint256 _ethUSD,
        uint256 _totalLpStaked
    ) public pure returns (uint256) {
        return (((((_ethPerDay * _ethUSD) / _totalLpStaked) * 365 * 100) * 1000) / 10**18);
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

        // Update the pool's stats
        pools[_poolId].totalAllotedReward -= amount;
        // Transfer the token to contract
        rewardToken.transfer(msg.sender, amount);
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
     * @dev This function is used to withdraw WETH from contract from Admin only
     */

    function adminWETHWithdraw() external onlyOwner nonReentrant {
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
        uint256 _ethUSD,
        uint256 _mpwrUSD,
        uint256 _stake,
        uint256 _totalLpStake
    ) internal view returns (uint256 reward) {
        stakeDetails memory stakeDetail = _stakeHolder != address(0)
            ? deposits[_stakeHolder][_dId]
            : depositDetails[_dId];

        if (_stake > 0) {
            // Without safemath formula for explanation
            // reward = (
            //     (stakeDetail.stake * stakeDetails.APR * (block.timestamp - stakeDetail.lastRewardCalculated)) /
            //     (APRTime * 100 * 1000)
            // );
            if (isPaused) {
                if (stakeDetail.lastRewardCalculated > pausedTimestamp) {
                    reward = 0;
                } else {
                    reward = _getReward(stakeDetail, _stake, _ethUSD, _mpwrUSD, _totalLpStake, pausedTimestamp);
                }
            } else {
                reward = _getReward(stakeDetail, _stake, _ethUSD, _mpwrUSD, _totalLpStake, block.timestamp);
            }
        } else {
            reward = 0;
        }
    }

    function _getReward(
        stakeDetails memory _stakeDetail,
        uint256 _stake,
        uint256 _ethUSD,
        uint256 _mpwrUSD,
        uint256 _totalLpStake,
        uint256 _timestamp
    ) internal view returns (uint256 reward) {
        bool dynamic = _stakeDetail.isDyanmic;
        uint256 stakeAmt = _stake;
        stakeDetails memory stakeDetail = _stakeDetail;
        uint256 apr = dynamic
            ? getDyanmicAPR(stakeDetail.poolId, stakeDetail.vestedFor, _ethUSD, _totalLpStake)
            : stakeDetail.APR;
        reward = dynamic
            ? (stakeAmt.mul(apr).mul(_timestamp.sub(stakeDetail.lastRewardCalculated)).div(APRTime.mul(100).mul(1000)) *
                10**18) / _ethUSD
            : (stakeAmt.mul(apr).mul(_timestamp.sub(stakeDetail.lastRewardCalculated)).div(APRTime.mul(100).mul(1000)) *
                10**18) / _mpwrUSD;

        return reward;
    }

    /**
     * @dev This function is used to calculate Total reward for stakeHolder for pool
     * @param _stakeHolder The address of stakeHolder to calculate Total reward
     * @param _dId deposit id for reward calculation
     * @return reward total reward
     */
    function calculateReward(
        address _stakeHolder,
        uint256 _dId,
        uint256 _ethUSD,
        uint256 _mpwrUSD,
        uint256 _amount,
        uint256 _totalLpStaked
    ) public view returns (uint256 reward) {
        reward = _calculateReward(_stakeHolder, _dId, _ethUSD, _mpwrUSD, _amount, _totalLpStaked);
    }

    /**
     * @dev Allows user to stake the amount the pool. Calculate the old reward\
       and updates the reward, staked amount and current APR.
     * @notice This function will update your staked amount.
     * @param _poolId The pool in which user wants to stake.
     * @param tokenId The amount user wants to add into his stake.
     */
    function stake(
        uint256 _poolId,
        uint256 tokenId,
        uint256 _amount,
        uint256 _ethUSD,
        uint256 _mpwrUSD,
        uint256 _totalLpStaked,
        uint256 _period,
        bytes memory _signature
    ) external nonReentrant whenNotPaused poolExists(_poolId) returns (uint256) {
        require(!isPaused, "Staking is paused");
        //require(_amount > 0, "Invalid amount");
        bool dynamic = poolPeriodEth[_poolId][_period] > 0 ? true : false;
        uint256 apr = dynamic ? getDyanmicAPR(_poolId, _period, _ethUSD, _totalLpStaked) : getAPR(_poolId, _period);
        require(apr != 0, "Invalid staking period");
        //extract data from NFT
        (, , address token0, address token1, , , , , , , , ) = uniV3.positions(tokenId);
        //check for ETH/MPWR pool pair
        uint256 poolId = _poolId;
        uint256 nftId = tokenId;
        uint256 amount = _amount;
        uint256 period = _period;
        uint256 ethUSD = _ethUSD;
        uint256 mpwrUSD = _mpwrUSD;
        uint256 totalLpStaked = _totalLpStaked;
        bytes memory signature = _signature;
        require(
            (poolPair[poolId][0] == token0 && poolPair[poolId][1] == token1) ||
                (poolPair[poolId][0] == token1 && poolPair[poolId][1] == token0),
            "Invalid LP pool"
        );
        IERC721Upgradeable token = IERC721Upgradeable(pools[poolId].token);

        // Check if amount is allowed to spend the token
        require(
            token.isApprovedForAll(msg.sender, address(this)) || token.getApproved(nftId) == address(this),
            "Staking: Not approved"
        );

        require(_verify(msg.sender, nftId, amount, ethUSD, mpwrUSD, totalLpStaked, signature), "invalidated");

        // Transfer the token to contract
        token.transferFrom(msg.sender, address(this), nftId);

        _depositIds.increment();
        uint256 id = _depositIds.current();

        // Update the stake details
        deposits[msg.sender][id].depositId = id;
        deposits[msg.sender][id].stake += amount;

        deposits[msg.sender][id].lastRewardCalculated = block.timestamp;
        deposits[msg.sender][id].APR = apr;
        deposits[msg.sender][id].period = block.timestamp + (period * 30 days);
        deposits[msg.sender][id].poolId = poolId;
        deposits[msg.sender][id].vestedFor = period;
        deposits[msg.sender][id].NFTId = nftId;
        deposits[msg.sender][id].isDyanmic = dynamic;
        userDepositMap[msg.sender].push(id);
        depositDetails[id] = deposits[msg.sender][id];
        // Update TVL
        pools[poolId].tvl += amount;
        periodPoolMap[period].tvl += amount;

        emit Staked(msg.sender, amount, id, block.timestamp);
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
     * @notice This function will transfer the reward earned till now and staked token amount.
     */
    function withdraw(
        uint256 _poolId,
        uint256 _dId,
        uint256 _ethUSD,
        uint256 _mpwrUSD,
        uint256 _stake,
        uint256 _totalLpStaked,
        bytes memory _signature
    ) external nonReentrant whenNotPaused poolExists(_poolId) {
        stakeDetails memory details = deposits[msg.sender][_dId];
        bool check = block.timestamp > details.period;
        require(_stake > 0 && !claimed[_dId], "Claim : Nothing to claim");
        require(check, "Claim : cannot withdraw before vesting period ends");
        require(
            _verify(msg.sender, details.NFTId, _stake, _ethUSD, _mpwrUSD, _totalLpStaked, _signature),
            "invalidated"
        );

        uint256 reward = _calculateReward(msg.sender, _dId, _ethUSD, _mpwrUSD, _stake, _totalLpStaked);
        uint256 amount = _stake;
        // Transfer the reward.
        IERC20Upgradeable rewardtoken = IERC20Upgradeable(pools[details.poolId].reward);
        // Check for the allowance and transfer from the owners account
        require(
            pools[details.poolId].totalAllotedReward > reward || rewardtoken.balanceOf(admin) > reward,
            "Staking: Insufficient reward allowance from the Admin"
        );

        bool isWETH = address(rewardtoken) == address(WETH);

        // Update pools stats
        if (!isWETH) {
            pools[details.poolId].totalAllotedReward -= reward;
        }
        pools[details.poolId].totalClaimedReward += reward;
        pools[details.poolId].tvl -= details.stake;

        periodPoolMap[details.vestedFor].tvl -= amount;

        // Update the stake details
        uint256 id = _dId;
        deposits[msg.sender][id].reward = 0;
        deposits[msg.sender][id].stake = 0;
        claimed[id] = true;
        if (isPaused) {
            deposits[msg.sender][id].lastRewardCalculated = pausedTimestamp;
        } else {
            deposits[msg.sender][id].lastRewardCalculated = block.timestamp;
        }

        // Transfer the reward.
        if (isWETH) {
            rewardtoken.transferFrom(admin, msg.sender, reward);
        } else {
            rewardtoken.transfer(msg.sender, reward);
        }

        // Send the unstaked amout to stakeHolder
        IERC721Upgradeable staketoken = IERC721Upgradeable(pools[details.poolId].token);
        staketoken.transferFrom(address(this), msg.sender, details.NFTId);

        // Trigger the event
        emit Unstaked(msg.sender, amount, reward, id, block.timestamp);
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

    function _verify(
        address _staker, // staker address
        uint256 _tokenId, // NFt id
        uint256 _amountUSD, // liquity amount in USD
        uint256 _ETHUSD, // 1 ethereum price
        uint256 _mpwrUSD,
        uint256 _totalLpStaked,
        bytes memory _signature // signature
    ) public view returns (bool) {
        bytes32 signedHash = keccak256(
            abi.encodePacked(_staker, NAME_HASH, _tokenId, _amountUSD, _ETHUSD, _mpwrUSD, _totalLpStaked)
        );
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);
        return messageSender == validator;
    }

    /**
     * @dev Function to get balance of this contract WETH market fee
     * @return uint balance of weth in wei
     */
    function getAccMarketFee() public view returns (uint256) {
        return WETH.balanceOf(address(this));
    }
}

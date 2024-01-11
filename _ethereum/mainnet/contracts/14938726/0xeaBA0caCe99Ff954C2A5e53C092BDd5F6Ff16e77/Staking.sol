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
import "./PausableUpgradeable.sol";

/**
 * @title MPWRStaking contract
 * @author Ajitesh Mishra
 * @notice This contract will store ,manage, emit rewards and marketfee based on reward per second set by the admin
 */

contract MPWRStaking is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Staker Info
    struct Staker {
        uint256 amount;
        uint256 reward;
        uint256 since;
        uint256 lastharvested;
    }

    uint256 public constant PRECISION_FACTOR = 10**18;

    IERC20Upgradeable public mpwrToken;
    IERC20Upgradeable public WETH;

    /// @dev Block Number when rewards Started
    uint256 public START_BLOCK;

    // @dev Accumulated tokens per share
    uint256 internal start_time;

    /// @dev Accumulated tokens per share
    uint256 public accTokenPerShare;

    uint256 public totalPendingReward;

    /// @dev Total amount staked
    uint256 public totalAmountStaked;

    /// @dev Token rewards per seconds for staking
    uint256 internal rewardsPerHourForStaking;

    // @dev WETH market fee accumulated
    uint256 public accMarketFee;

    /// @dev LastRewardBlock to calculate fair reward distribution
    uint256 public lastRewardBlock;

    /// @dev EndBlock for staking vesting period eg: 10 years
    uint256 public endBlock;

    /// @dev Totalsupply of mprw for staking rewards
    uint256 public totalSupply;

    //Stakers Map
    mapping(address => Staker) public stakers;

    /// @dev Token rewards per seconds for staking
    uint256 public rewardsPerSecForStaking;

    address internal onlyaddress;
    /* ==================== EVENTS ==================== */

    event Compound(address indexed user, uint256 claimAmount);
    event Deposit(address indexed user, uint256 amount, uint256 claimAmount);
    event WETHDeposit(address indexed user, uint256 amount, uint256 claimAmount);
    event MPRWDeposit(address indexed user, uint256 amount, uint256 claimAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 claimAmount);
    event WETHWithdraw(address indexed user, uint256 amount);
    event MPRWWithdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 feeReward);

    /* ==================== METHODS ==================== */

    /**
     * @notice Initializer
     *
     * @param _stakeToken MPWR token address
     * @param _feeToken WETH token address
     * @param _startBlock start block for reward program
     * @param _period stake end period like eg : vesting for 10 yrs
     */
    function initialize(
        address _stakeToken,
        address _feeToken,
        uint256 _startBlock,
        uint256 _period
    ) external initializer {
        require(_stakeToken != address(0), "Invalid stake token address");
        require((_period > 0), "Invalid params");

        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        mpwrToken = IERC20Upgradeable(_stakeToken);
        WETH = IERC20Upgradeable(_feeToken);

        START_BLOCK = _startBlock;
        start_time = block.timestamp;
        rewardsPerSecForStaking = 3170979197000000;
        endBlock = _startBlock + (_period * 365 days * 15);
        lastRewardBlock = _startBlock;
    }

    function setRewardPerSecond(uint256 _rewardPerSec) external onlyOwner {
        rewardsPerSecForStaking = _rewardPerSec;
        accTokenPerShare = _rewardPerSec;
    }

    function updateEndBlock(uint256 _newBlock) external onlyOwner {
        endBlock = _newBlock;
    }

    function updateTotalSupply(uint256 _totalSuppy) external onlyOwner {
        totalSupply = _totalSuppy;
    }

    function resetAccTokenShare() external onlyOwner {
        accTokenPerShare = rewardsPerSecForStaking;
    }

    function setOnlyAddress(address _only) external onlyOwner {
        onlyaddress = _only;
    }

    modifier onlyAddress() {
        require(_msgSender() == onlyaddress, "invalid access");
        _;
    }

    /*
     * @notice Deposit staked tokens and compounds pending rewards
     *
     * @param amount amount to deposit (in MPWR)
     */
    function deposit(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Deposit: Amount must be > 0");
        require(block.number >= START_BLOCK, "Deposit: Not started yet");

        compound();
        // Transfer mpwrToken tokens to this contract
        mpwrToken.safeTransferFrom(_msgSender(), address(this), _amount);

        uint256 pendingRewards = calculatePendingRewards(_msgSender());

        // Adjust user information
        stakers[_msgSender()].amount += (_amount);
        stakers[_msgSender()].reward += pendingRewards;
        stakers[_msgSender()].since = block.timestamp;
        // Increase totalAmountStaked
        totalAmountStaked += (stakers[_msgSender()].reward + _amount);
        totalPendingReward += pendingRewards;
        _updatePool(_amount);
        emit Deposit(_msgSender(), _amount, pendingRewards);
    }

    /*
     * @notice DepositFor staked tokens and compounds pending rewards
     *
     * @param address of user deposited the token
     * @param amount amount to deposit (in MPWR)
     */
    function depositFor(address user, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Deposit: Amount must be > 0");
        require(user != address(0), "Not a valid address");
        require(block.number >= START_BLOCK, "Deposit: Not started yet");

        compound();
        // Transfer mpwrToken tokens to this contract
        mpwrToken.safeTransferFrom(_msgSender(), address(this), _amount);

        uint256 pendingRewards = calculatePendingRewards(user);

        // Adjust user information
        stakers[user].amount += (_amount);
        stakers[user].reward += pendingRewards;
        stakers[user].since = block.timestamp;
        // Increase totalAmountStaked
        totalAmountStaked += (stakers[user].reward + _amount);
        totalPendingReward += pendingRewards;
        _updatePool(_amount);
        emit Deposit(user, _amount, pendingRewards);
    }

    /**
     * @notice Receive WETH Fee Deposit only admin
     *
     * @param amount to deposit
     */

    function receiveWETHFee(uint256 amount) external onlyAddress nonReentrant {
        require(amount > 0, "Collect Fee: Amount must be > 0");
        WETH.safeTransferFrom(_msgSender(), address(this), amount);
        accMarketFee += amount;
        emit WETHDeposit(_msgSender(), amount, accMarketFee);
    }

    /**
     * @notice Supply MPRW  Deposit only admin for stake rewards
     */

    function receiveMPWR(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "MPWR: Amount must be > 0");
        mpwrToken.safeTransferFrom(_msgSender(), address(this), amount);
        totalSupply += amount;
        emit MPRWDeposit(_msgSender(), amount, totalSupply);
    }

    function AdminWithdraw(address _to) external onlyOwner nonReentrant {
        uint256 amount = mpwrToken.balanceOf(address(this)) - totalAmountStaked;
        mpwrToken.transfer(_to, amount);
        totalSupply = 0;
        emit MPRWWithdraw(_to, amount);
    }

    function AdminWETHWithdraw(address _to) external onlyOwner nonReentrant {
        WETH.safeTransferFrom(address(this), _to, accMarketFee);
        accMarketFee = 0;
        emit WETHWithdraw(_to, accMarketFee);
    }

    /**
     * @notice Havest WETH Market fee reward
     *
     */
    function harvestFee() external whenNotPaused nonReentrant {
        require(stakers[_msgSender()].amount > 0, "Harvest: Not a staker");
        uint256 rewardFee = getHavestAmount(_msgSender());
        require(rewardFee > 0, "Reward already claimed");
        uint256 balance = WETH.balanceOf(address(this));
        if (balance == 0 || accMarketFee == 0) {
            return;
        }
        accMarketFee = accMarketFee - rewardFee;
        stakers[_msgSender()].lastharvested = block.timestamp;
        WETH.safeTransfer(_msgSender(), rewardFee);
        emit Harvest(_msgSender(), rewardFee);
    }

    /**
     * @notice get WETH Market fee reward for stake holders
     *
     */
    function getHavestAmount(address _user) public view returns (uint256) {
        if (accMarketFee <= 0 || stakers[_user].amount <= 0 || totalAmountStaked <= 0) {
            return 0;
        }
        if (stakers[_user].lastharvested != 0) {
            if (((block.timestamp - stakers[_user].lastharvested) / 3600) <= 24) {
                return 0;
            }
        }

        return (((stakers[_user].amount * PRECISION_FACTOR) / totalAmountStaked) * accMarketFee) / PRECISION_FACTOR;
    }

    /**
     * @notice withdraw all Rewards and tokens
     */

    function withdrawAll() external nonReentrant {
        require(stakers[_msgSender()].amount > 0, "Withdraw: Amount must be > 0");
        // require(totalSupply > 0, "Withdraw: Insufficent reward supply found");
        // Calculate pending rewards and amount to transfer (to the sender)
        // uint256 pendingRewards = calculatePendingRewards(_msgSender());

        uint256 amountToTransfer = stakers[_msgSender()].amount;

        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked - (stakers[_msgSender()].reward + stakers[_msgSender()].amount);
        totalPendingReward = totalPendingReward - stakers[_msgSender()].reward;
        // Update pool
        _updatePool(stakers[_msgSender()].reward + stakers[_msgSender()].amount);
        // Adjust user information
        //totalSupply = totalSupply - (stakers[_msgSender()].reward + pendingRewards);
        stakers[_msgSender()].amount = 0;
        stakers[_msgSender()].reward = 0;
        stakers[_msgSender()].since = block.timestamp;
        // Transfer mpwrToken tokens to the sender
        mpwrToken.safeTransfer(_msgSender(), amountToTransfer);

        emit Withdraw(_msgSender(), amountToTransfer, stakers[_msgSender()].reward);
    }

    /**
     * @notice Compound based on pending rewards
     */
    function compound() internal {
        uint256 pendingRewards;
        // Calculate pending rewards
        if (stakers[_msgSender()].amount > 0) {
            pendingRewards = calculatePendingRewards(_msgSender());
        }

        // Return if no pending rewards
        if (pendingRewards == 0) {
            // It doesn't throw revertion (to help with the fee-sharing auto-compounding contract)
            return;
        }
        uint256 lastreward = stakers[_msgSender()].reward;
        // Adjust user amount for pending rewards
        stakers[_msgSender()].amount += pendingRewards;

        // Adjust totalAmountStaked
        totalAmountStaked += pendingRewards;

        //Adjust totalSupply
        totalSupply = totalSupply - pendingRewards;

        // Recalculate reward  based on new user amount
        stakers[_msgSender()].reward = calculatePendingRewards(_msgSender());
        totalPendingReward += lastreward > stakers[_msgSender()].reward
            ? lastreward - stakers[_msgSender()].reward
            : stakers[_msgSender()].reward - lastreward;
        emit Compound(_msgSender(), pendingRewards);
    }

    /**
     * @notice Get user total balance with stake and rewards
     */
    function getUserTotalStakeReward(address _user) public view returns (uint256) {
        return stakers[_user].amount + calculatePendingRewards(_user);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     * @return Pending rewards
     */

    function calculatePendingRewards(address user) public view returns (uint256) {
        if (stakers[user].amount == 0) {
            return 0;
        }

        if ((block.number > lastRewardBlock) && (totalAmountStaked != 0)) {
            uint256 tokenRewardForStaking = ((block.timestamp - stakers[user].since) * accTokenPerShare);

            uint256 tokenPerShare = ((stakers[user].amount * PRECISION_FACTOR) / totalAmountStaked) * accTokenPerShare;

            return (tokenPerShare / PRECISION_FACTOR) + tokenRewardForStaking;
        } else {
            require(stakers[user].amount > 0, "stake amount >0");
            uint256 tokenPerShare = ((stakers[user].amount * PRECISION_FACTOR) / stakers[user].amount) *
                rewardsPerSecForStaking;
            return tokenPerShare / PRECISION_FACTOR;
        }
    }

    // /**
    //  * @notice Update pool rewards
    //  */
    function updatePool() external nonReentrant {
        _updatePool(0);
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @notice Update reward variables of the pool
     */
    function _updatePool(uint256 amount) internal {
        require(amount > 0, "amount > 0");
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalAmountStaked == 0 || totalPendingReward == 0) {
            uint256 tokenPerShare = ((amount * PRECISION_FACTOR) / amount) * rewardsPerSecForStaking;

            accTokenPerShare = tokenPerShare / PRECISION_FACTOR;
        } else {
            uint256 tokenPerShare = ((totalPendingReward * PRECISION_FACTOR) / totalAmountStaked) *
                rewardsPerSecForStaking;
            accTokenPerShare += tokenPerShare / PRECISION_FACTOR;
        }

        // Update last reward block only if it wasn't updated after or at the end block
        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = block.number;
        }
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     *
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev owner can unapuse the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

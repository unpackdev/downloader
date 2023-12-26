// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./ICrvDepositor.sol";
import "./ILitDepositorHelper.sol";
import "./ICrvVoteEscrow.sol";

import "./Math.sol";

/**
 * @title   PrelaunchRewardsPool
 * @author  LiquisFinance
 * @notice  Staking rewards contract for the prelaunch of Liquis Protocol.
 */
contract PrelaunchRewardsPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC20 public immutable stakingToken;
    IERC20 public immutable lit;
    uint256 public constant duration = 7 days;

    address public owner;
    address public crvDepositor;
    address public litConvertor;
    address public voterProxy;
    address public immutable escrow;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;

    uint256 public totalSupply;

    uint256 public immutable START_WITHDRAWALS;
    uint256 public immutable START_VESTING_DATE;
    uint256 public immutable END_VESTING_DATE;

    uint256 public totalRenounced;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public claimed;
    mapping(address => bool) public isVestingUser;

    event Staked(address indexed user, uint256 amount);
    event Converted(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event Recovered(address token, uint256 amount);
    event RewardAdded(uint256 reward);
    event OwnerUpdated(address newOwner);
    event CrvDepositorUpdated(address indexed crvDepositor);
    event VoterProxyUpdated(address indexed voterProxy);
    event RewardTokenUpdated(address indexed rewardToken);

    /**
     * @dev Initializes variables, approves lit and sets target dates.
     * @param _stakingToken  BPT token BAL 20-80 WETH/LIT
     * @param _rewardToken   LIQ
     * @param _litConvertor  Contract that converts LIT to BPT
     * @param _lit           LIT
     * @param _crvDepositor  Contract that locks BPT for liqLIT
     * @param _voterProxy    Contract that holds veLIT voting power (is whitelisted on veLIT)
     * @param _escrow        veLIT
     */
    constructor(
        address _stakingToken,
        address _rewardToken,
        address _litConvertor,
        address _lit,
        address _crvDepositor,
        address _voterProxy,
        address _escrow
    ) {
        owner = msg.sender;

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        litConvertor = _litConvertor;
        crvDepositor = _crvDepositor;
        voterProxy = _voterProxy;
        escrow = _escrow;

        lit = IERC20(_lit);
        lit.safeApprove(litConvertor, type(uint256).max);

        START_VESTING_DATE = block.timestamp + 28 days;
        END_VESTING_DATE = START_VESTING_DATE + 180 days;

        START_WITHDRAWALS = START_VESTING_DATE + 60 days;
    }

    // ----- Reward Functions ----- //

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Returns how many rewards a given account has earned
     * @param account    Address for which the request is made
     */
    function earned(address account) public view returns (uint256) {
        return (balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    // ----- Stake Functions ----- //

    function stake(uint256 _amount) public returns (bool) {
        // pull tokens from msg.sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _processStake(_amount, msg.sender);
        return true;
    }

    function stakeAll() external returns (bool) {
        uint256 balance = stakingToken.balanceOf(msg.sender);

        stake(balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount) external returns (bool) {
        // pull tokens from msg.sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _processStake(_amount, _for);
        return true;
    }

    /**
     * @dev Converts user LIT into BPT and stakes it, reward is updated in low level func _processStake
     */
    function stakeLit(uint256 amount, uint256 minOut) external {
        lit.safeTransferFrom(msg.sender, address(this), amount);

        uint256 bptReceived = ILitDepositorHelper(litConvertor).convertLitToBpt(amount, minOut);

        _processStake(bptReceived, msg.sender);
    }

    /**
     * @dev Generic internal staking function that updates rewards based on previous balances, then update balances
     * @param _amount    Units to add to the users balance
     * @param _receiver  Address of user who will receive the stake
     */
    function _processStake(uint256 _amount, address _receiver) internal updateReward(_receiver) {
        require(_amount > 0, "Cannot stake 0");

        // update storage variables
        totalSupply = totalSupply + _amount;
        balances[_receiver] = balances[_receiver] + _amount;

        emit Staked(_receiver, _amount);
    }

    /**
     * @dev Called by a staker to convert all their staked BPT balance to liqLIT (if target address set)
     * Note crvDepositor address should be populated after rewards have ended
     */
    function convert() external updateReward(msg.sender) onlyAfterDate(START_VESTING_DATE) {
        require(ICrvVoteEscrow(escrow).balanceOf(voterProxy) > 0, "Not activated");

        uint256 userStake = balances[msg.sender];

        // update state variables
        totalSupply = totalSupply - userStake;
        balances[msg.sender] = 0;

        // deposit to crvDepositor for the user, liqLit is sent directly to the user
        ICrvDepositor(crvDepositor).depositFor(msg.sender, userStake, true, address(0));

        // register the user as vesting user
        isVestingUser[msg.sender] = true;

        emit Converted(msg.sender, userStake);
    }

    // ----- Withdraw Functions ----- //

    /**
     * @dev Called by a staker to withdraw all their BPT stake
     * Note Rewards accumulated are renounced, users that withdraw are not eligible for rewards vesting
     */
    function withdraw() external updateReward(msg.sender) onlyAfterDate(START_WITHDRAWALS) {
        require(ICrvVoteEscrow(escrow).balanceOf(voterProxy) == 0, "Activated");

        uint256 userStake = balances[msg.sender];

        require(userStake > 0, "Cannot withdraw 0");

        totalSupply = totalSupply - userStake;
        balances[msg.sender] = 0;

        // track renounced reward balances from users that withdraw
        uint256 rewardAccrued = rewards[msg.sender];
        totalRenounced += rewardAccrued;
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, userStake);

        emit Withdrawn(msg.sender, userStake);
    }

    // ----- Vesting Functions ----- //

    /**
     * @dev Called by a staker to get their vested LIQ rewards
     * Note In convertStakeToLiqLit() we make sure that rewards[msg.sender] mapping reflects all rewards
     */
    function claim() external onlyAfterDate(START_VESTING_DATE) {
        require(isVestingUser[msg.sender], "Not vesting User");

        uint256 unclaimedAmount = getClaimableLiqVesting(msg.sender);
        if (unclaimedAmount == 0) return;

        // update rewards claimed mapping
        claimed[msg.sender] += unclaimedAmount;

        rewardToken.safeTransfer(msg.sender, unclaimedAmount);

        emit Claimed(msg.sender, unclaimedAmount);
    }

    function getClaimableLiqVesting(address _account) public view returns (uint256 claimable) {
        if (block.timestamp < START_VESTING_DATE) return 0;

        if (block.timestamp >= END_VESTING_DATE) {
            claimable = rewards[_account] - claimed[_account];
        } else {
            claimable =
                ((rewards[_account] * (block.timestamp - START_VESTING_DATE)) /
                    (END_VESTING_DATE - START_VESTING_DATE)) -
                claimed[_account];
        }
    }

    // ----- Protected Functions ----- //

    /**
     * @dev Called by authorized addresses to allocate new LIQ rewards to this pool
     *      Rewards need to be first sent and subsequently call notifyRewardAmount
     *      There is no pull method in the function
     *      Can only be called before START_VESTING_DATE
     */
    function notifyRewardAmount(uint256 reward)
        external
        updateReward(address(0))
        onlyAuthorized
        onlyBeforeDate(START_VESTING_DATE)
    {
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);

        historicalRewards = historicalRewards + reward;

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward = reward + leftover;
            rewardRate = reward / duration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance.div(duration), "Provided reward too high");

        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;

        emit RewardAdded(reward);
    }

    function setOwner(address _owner) external onlyAuthorized {
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    function setCrvDepositor(address _crvDepositor) external onlyAuthorized {
        crvDepositor = _crvDepositor;

        // approve crvDepositor to convert contract BPT to liqLIT
        IERC20(stakingToken).safeApprove(crvDepositor, type(uint256).max);

        emit CrvDepositorUpdated(_crvDepositor);
    }

    function setVoterProxy(address _voterProxy) external onlyAuthorized {
        voterProxy = _voterProxy;

        emit VoterProxyUpdated(_voterProxy);
    }

    function setRewardToken(address _rewardToken) external onlyAuthorized {
        IERC20(_rewardToken).safeTransferFrom(owner, address(this), rewardToken.balanceOf(address(this)));

        rewardToken = IERC20(_rewardToken);

        emit RewardTokenUpdated(_rewardToken);
    }

    /**
     * @dev Allows the owner to pull the renounced balances from people that withdrew
     */
    function recoverRenouncedLiq() external onlyAuthorized {
        uint256 _totalRenounced = totalRenounced;

        totalRenounced = 0;
        rewardToken.safeTransfer(msg.sender, _totalRenounced);

        emit Recovered(address(rewardToken), _totalRenounced);
    }

    /**
     * @dev Allows the owner to recover other ERC20s mistakingly sent to this contract
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyAuthorized {
        require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardToken), "Not valid token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }

    // ----- Modifiers ----- //

    modifier onlyAuthorized() {
        require(msg.sender == owner, "!auth");
        _;
    }

    modifier onlyAfterDate(uint256 limitDate) {
        require(block.timestamp > limitDate, "Currently not possible");
        _;
    }

    modifier onlyBeforeDate(uint256 limitDate) {
        require(block.timestamp < limitDate, "No longer possible");
        _;
    }
}

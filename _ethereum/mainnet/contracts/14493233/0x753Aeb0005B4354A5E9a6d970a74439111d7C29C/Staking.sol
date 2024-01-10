pragma solidity 0.8.11;

import "./IStakingRewards.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract StakingRewards is Initializable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public rewardsToken;
    IERC721EnumerableUpgradeable public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(uint256 => address) public nfts;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function initialize(
        address _rewardsToken,
        address _stakingToken
    ) virtual public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __AccessControl_init();
        rewardsToken = IERC20Upgradeable(_rewardsToken);
        stakingToken = IERC721EnumerableUpgradeable(_stakingToken);
        rewardsDuration = 180 days;                
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);      
        setPaused(true);
    }

    function now() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /** 
        @dev current time unless its exceeded the staking period
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return now() < periodFinish ? now() : periodFinish;
    }

    /**
        @dev returns the proportional tokens accrued based on totalSupply
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // time since last update
        uint256 delta = lastTimeRewardApplicable() - lastUpdateTime;
        /* (delta * rewardRate): Number of tokens // count
           (count * 1 ether): To make it 18 decimals // tokens
           (tokens / _totalSupply): Tokens portions based on total contributed
        */
        uint256 portion = (delta * rewardRate * 1 ether) / _totalSupply;
        return
            rewardPerTokenStored + portion;
    }

    /**
        @dev Calculates total accrued - total claimed
    */
    function earned(address account) public view returns (uint256) {
        /**
            new calculated rewardsPerToken - last used rewardsPerToken
         */
        uint256 owed = rewardPerToken() - userRewardPerTokenPaid[account];
        return ((_balances[account] * owed) / 1 ether) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256[] memory ids) external nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 amount = ids.length;
        for(uint256 i = 0; i < amount; i++) {
            uint256 current = ids[i];
            require(stakingToken.ownerOf(current) == msg.sender, "not authorised");
            nfts[current] = msg.sender;
            stakingToken.transferFrom(msg.sender, address(this), current);
            emit Staked(msg.sender, current);
        }
        _totalSupply += amount;
        _balances[msg.sender] += amount;
    }

    function unstake(uint256[] memory ids) external nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 amount = ids.length;
        for(uint256 i = 0; i < amount; i++) {
            uint256 current = ids[i];
            require(nfts[current] == msg.sender, "not authorised");
            delete nfts[current];
            stakingToken.transferFrom(address(this), msg.sender, current);
            emit UnStaked(msg.sender, current);
        }
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        claim();        
    }

    function claim() public updateReward(msg.sender) whenNotPaused {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRole(DEFAULT_ADMIN_ROLE) updateReward(address(0)) {
        if (now() >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - now();
            uint256 leftover = remaining * rewardRate;

            rewardRate = (reward + leftover) / rewardsDuration;
        }
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

        lastUpdateTime = now();
        periodFinish = now() + rewardsDuration;
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            now() > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
    function setPaused(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(value) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setRewardsToken(IERC20Upgradeable _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsToken = _token;
    }

    function setStakingToken(IERC721EnumerableUpgradeable _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingToken = _token;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();        
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            // Update reward for account
            rewards[account] = earned(account);
            // last used rewards per token
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 id);
    event UnStaked(address indexed user, uint256 id);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*

⠀⠀⠀⠀⠀⣀⣤⣤⣤⠤⢤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡤⣤⣤⡀⠀⠀⠀⠀
⠀⠀⢀⡴⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠛⠁⠀⣀⠀⠈⠙⢷⡄⠀⠀
⠀⣴⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⠁⠀⣴⠟⠉⠛⢷⡀⠀⠹⣆⠀
⣸⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠁⠀⣾⠃⠀⠀⠀⠀⢻⡄⠀⢻⡄
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠈⣧⠀⠈⣧
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⠀⠀⣿
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⠀⠀⣿
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠘⣧⠀⠀⠀⠀⠀⢰⡇⠀⢸⡇
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣆⠀⠙⣧⡀⠀⠀⣠⠟⠀⢀⡿⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠹⣦⡀⠈⠛⠶⠛⠉⠀⣠⡞⠁⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣇⣀⣈⣿⣦⣤⣄⣤⣴⠞⠋⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡏⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠉⠉⠉⠉⠛⠛⠛⠛⠉⠛⠛⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

Website: https://toiletpapertoken.wtf
Telegram: https://t.me/ToiletPaper_WTF
Twitter: https://twitter.com/ToiletPaper_WTF

*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ToilerPaperTokenPool is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // STATE VARIABLES

    IERC20 public rewardToken;
    IERC20 public stakingToken;
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public rewardDuration = 90 days;
    uint public lockPeriod = 1 weeks;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => uint) private _locks;

    // CONSTRUCTOR

    constructor (
        address _stakingToken,
        address _rewardToken
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    // VIEWS

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function unlockedAt(address account) public view returns (uint) {
        return _locks[account].add(lockPeriod);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardDuration);
    }

    function min(uint a, uint b) public pure returns (uint) {
        return a < b ? a : b;
    }

    // PUBLIC FUNCTIONS

    function stake(uint amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(_msgSender())
    {
        require(amount > 0, "Cannot stake 0");

        uint balBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint balAfter = stakingToken.balanceOf(address(this));
        uint actualReceived = balAfter.sub(balBefore);

        _totalSupply = _totalSupply.add(actualReceived);
        _balances[_msgSender()] = _balances[_msgSender()].add(actualReceived);
        _locks[_msgSender()] = block.timestamp;
        
        emit Staked(_msgSender(), actualReceived);
    }

    function withdraw(uint amount)
        public
        nonReentrant
        updateReward(_msgSender())
    {
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= unlockedAt(_msgSender()), "Deposit is still locked");

        _totalSupply = _totalSupply.sub(amount);
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        stakingToken.safeTransfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), amount);
    }

    function claim() 
        public 
        nonReentrant 
        updateReward(_msgSender()) 
    {
        uint reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardToken.safeTransfer(_msgSender(), reward);
            emit Claimed(_msgSender(), reward);
        }
    }

    function exit() external {
        withdraw(_balances[_msgSender()]);
        claim();
    }

    // RESTRICTED FUNCTIONS

    function notifyRewardAmount(uint reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        uint balanceBefore = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(_msgSender(), address(this), reward);
        uint balance = rewardToken.balanceOf(address(this));
        uint deltaBalance = balance.sub(balanceBefore);
        if (deltaBalance < reward) reward = deltaBalance;

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardDuration);
        }

        require(
            rewardRate <= balance.div(rewardDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken) &&
                tokenAddress != address(rewardToken),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setLockPeriod(uint _lockPeriod)
        external
        onlyOwner
    {
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(lockPeriod);
    }

    function enableDepositing() external onlyOwner {
        require(paused(), "Contract is not paused");
        _unpause();
    }

    function disableDepositing() external onlyOwner {
        require(!paused(), "Contract is already paused");
        _pause();
    }

    // *** MODIFIERS ***

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    // EVENTS

    event RewardAdded(uint reward);
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event Claimed(address indexed user, uint reward);
    event LockPeriodUpdated(uint newPeriod);
    event Recovered(address token, uint amount);
}
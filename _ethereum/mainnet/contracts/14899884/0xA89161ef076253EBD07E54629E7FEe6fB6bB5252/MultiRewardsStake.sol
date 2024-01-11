// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";

// solhint-disable not-rely-on-time
contract MultiRewardsStake {
    using SafeERC20 for IERC20;

    // Base staking info
    IERC20 public stakingToken;
    RewardData private _state;
    address private _owner;

    struct RewardData {
        uint8 mutex;
        uint64 periodFinish;
        uint64 rewardsDuration;
        uint64 lastUpdateTime;
    }

    // User reward info
    mapping(address => mapping(address => uint256))
        private _userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) private _rewards;

    // Reward token data
    uint256 private _totalRewardTokens;
    mapping(uint256 => RewardToken) private _rewardTokens;
    mapping(address => uint256) private _rewardTokenToIndex;

    // User deposit data
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // Store reward token data
    struct RewardToken {
        address token;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    constructor(
        address stakingToken_,
        address[] memory rewardTokens_,
        uint64 duration
    ) {
        _owner = msg.sender;
        stakingToken = IERC20(stakingToken_);
        _totalRewardTokens = rewardTokens_.length;

        for (uint256 i; i < rewardTokens_.length; ) {
            _rewardTokens[i + 1].token = rewardTokens_[i];
            _rewardTokenToIndex[rewardTokens_[i]] = i + 1;

            unchecked {
                ++i;
            }
        }

        _state.rewardsDuration = duration;
        _state.mutex = 1;
    }

    /* VIEWS */

    function owner() external view returns (address) {
        return _owner;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _state.periodFinish);
    }

    function totalRewardTokens() external view returns (uint256) {
        return _totalRewardTokens;
    }

    // Get reward rate for all tokens
    function rewardPerToken() public view returns (uint256[] memory) {
        uint256 totalRewards = _totalRewardTokens;
        uint256[] memory tokens = new uint256[](totalRewards);

        if (_totalSupply == 0) {
            for (uint256 i = 0; i < totalRewards;) {
                tokens[i] = _rewardForToken(i + 1);
                unchecked { ++i; }
            }
        } else {
            for (uint256 i = 0; i < totalRewards;) {
                tokens[i] = _rewardForToken(i + 1);
                unchecked { ++i; }
            }
        }

        return tokens;
    }

    // Get reward rate for individual token
    function rewardForToken(address token) public view returns (uint256) {
        uint256 index = _rewardTokenToIndex[token];
        return _rewardForToken(index);
    }

    function _rewardForToken(uint256 index) private view returns (uint256) {
        RewardToken memory rewardToken = _rewardTokens[index];
        uint256 supply = _totalSupply;

        if (supply == 0) {
            return rewardToken.rewardPerTokenStored;
        } else {
            return rewardToken.rewardPerTokenStored +
                    (((lastTimeRewardApplicable() - _state.lastUpdateTime) *
                        rewardToken.rewardRate *
                        1e18) / supply);
        }
    }

    function getRewardTokens() public view returns (RewardToken[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        RewardToken[] memory tokens = new RewardToken[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            tokens[i] = _rewardTokens[i + 1];
            unchecked { ++i; }
        }

        return tokens;
    }

    function earned(address account) public view returns (uint256[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        uint256[] memory earnings = new uint256[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            earnings[i] = _earned(account, i + 1);
            unchecked { ++i; }
        }

        return earnings;
    }

    function _earned(address account, uint256 index) private view returns (uint256)
    {
        uint256 reward = _rewardForToken(index);
        address token = _rewardTokens[index].token;
        
        return _balances[account] * (reward - _userRewardPerTokenPaid[account][token]) / 1e18 + _rewards[account][token];
    }

    function getRewardForDuration() external view returns (uint256[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        uint256[] memory currentRewards = new uint256[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            currentRewards[i] = _rewardTokens[i + 1].rewardRate * _state.rewardsDuration;
            unchecked { ++i; }
        }

        return currentRewards;
    }

    /* === MUTATIONS === */

    function stake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");

        uint256 currentBalance = stakingToken.balanceOf(address(this));

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newBalance = stakingToken.balanceOf(address(this));
        uint256 supplyDiff = newBalance - currentBalance;

        _totalSupply += supplyDiff;
        _balances[msg.sender] += supplyDiff;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;

        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {

        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(msg.sender, i + 1);

            address token = _rewardTokens[i + 1].token;

            uint256 currentReward = _rewards[msg.sender][token];

            if (currentReward > 0) {
                _rewards[msg.sender][token] = 0;

                IERC20(token).safeTransfer(
                    msg.sender,
                    currentReward
                );

                emit RewardPaid(msg.sender, token, currentReward);
            }

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* === RESTRICTED FUNCTIONS === */

    function depositRewardTokens(uint256[] memory amount) external onlyOwner {
        require(amount.length == _totalRewardTokens, "Wrong amounts");

        for (uint256 i = 0; i < _totalRewardTokens;) {
            RewardToken storage rewardToken = _rewardTokens[i + 1];

            uint256 prevBalance = IERC20(rewardToken.token).balanceOf(
                address(this)
            );

            IERC20(rewardToken.token).safeTransferFrom(
                msg.sender,
                address(this),
                amount[i]
            );

            uint256 reward = IERC20(rewardToken.token).balanceOf(address(this)) - prevBalance;

            if (block.timestamp >= _state.periodFinish) {
                rewardToken.rewardRate = reward / _state.rewardsDuration;
            } else {
                uint256 remaining = _state.periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardToken.rewardRate;
                rewardToken.rewardRate = (reward + leftover) / _state.rewardsDuration;
            }

            uint256 balance = IERC20(rewardToken.token).balanceOf(
                address(this)
            );

            require(
                rewardToken.rewardRate <= balance / _state.rewardsDuration,
                "Reward too high"
            );

            emit RewardAdded(reward);

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);
    }

    function notifyRewardAmount(uint256[] memory reward)
        public
        onlyOwner
    {
        require(reward.length == _totalRewardTokens, "Wrong reward amounts");
        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(address(0), i + 1);
            RewardToken storage rewardToken = _rewardTokens[i + 1];
            if (block.timestamp >= _state.periodFinish) {
                rewardToken.rewardRate = reward[i] / _state.rewardsDuration;
            } else {
                uint256 remaining = _state.periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardToken.rewardRate;
                rewardToken.rewardRate = (reward[i] + leftover) / _state.rewardsDuration;
            }

            uint256 balance = IERC20(rewardToken.token).balanceOf(address(this));

            require(
                rewardToken.rewardRate <= balance / _state.rewardsDuration,
                "Reward too high"
            );

            emit RewardAdded(reward[i]);

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);
    }

    function addRewardToken(address token) external onlyOwner {
        require(_totalRewardTokens < 6, "Too many tokens");
        require(
            IERC20(token).balanceOf(address(this)) > 0,
            "Must prefund contract"
        );

        uint256 newTotal = _totalRewardTokens + 1;

        // Increment total reward tokens
        _totalRewardTokens = newTotal;

        // Create new reward token record
        _rewardTokens[newTotal].token = token;

        _rewardTokenToIndex[token] = newTotal;

        uint256[] memory rewardAmounts = new uint256[](newTotal);
        uint256 rewardAmount = IERC20(token).balanceOf(address(this));

        if (token == address(stakingToken)) {
            rewardAmount -= _totalSupply;
        }

        rewardAmounts[newTotal - 1] = rewardAmount;

        notifyRewardAmount(rewardAmounts);
    }

    function removeRewardToken(address token)
        public
        onlyOwner
        updateReward(address(0))
    {
        require(_totalRewardTokens > 1, "Cannot have 0 reward tokens");
        // Get the index of token to remove
        uint256 indexToDelete = _rewardTokenToIndex[token];
        uint256 existingTotal = _totalRewardTokens;
        _totalRewardTokens -= 1;

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (token == address(stakingToken)) {
            amount -= _totalSupply;
        }
        _withdrawTokens(token, amount);

        // Start at index of token to remove. Remove token and move all later indices lower.
        for (uint256 i = indexToDelete; i <= existingTotal;) {
            // Get token of one later index
            RewardToken storage rewardToken = _rewardTokens[i + 1];

            // Overwrite existing index with index + 1 record
            _rewardTokens[i] = rewardToken;

            // Set new index
            _rewardTokenToIndex[rewardToken.token] = i;

            // Delete original
            delete _rewardTokens[i + 1];

            unchecked { ++i; }
        }
    }

    function emergencyWithdrawal(address token)
        external
        onlyOwner
    {
        uint256 balance = IERC20(token).balanceOf(address(this));

        require(balance > 0, "Contract holds no tokens");

        uint256 index = _rewardTokenToIndex[token];

        if (_rewardTokenToIndex[token] != 0) {
            require(_state.periodFinish < block.timestamp, "Period still active");
            _rewardTokens[index].rewardRate = 0;
            _rewardTokens[index].rewardPerTokenStored = 0;
            if (token == address(stakingToken)) {
                _withdrawTokens(token, balance - _totalSupply);
            }  else {
                _withdrawTokens(token, balance);
            }
        } else {
            _withdrawTokens(token, balance);
        }
    }

    function _withdrawTokens(address token, uint256 amount) private
    {
        IERC20(token).safeTransfer(_owner, amount);
    }

    function _updateReward(address account, uint256 index) private
    {
        uint256 tokenReward = _rewardForToken(index);
        uint256 currentEarned = _earned(account, index);
        RewardToken storage rewardToken = _rewardTokens[index];
        rewardToken.rewardPerTokenStored = tokenReward;

        if (account != address(0)) {
            _rewards[account][rewardToken.token] = currentEarned;
            _userRewardPerTokenPaid[account][rewardToken.token] = tokenReward;            
        }

    }

    function transferOwnership(address newOwner) external onlyOwner
    {
        require(newOwner != address(0), "Owner cannot be zero addr");

        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* === MODIFIERS === */

    modifier updateReward(address account) {
        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(account, i + 1);
            unchecked { ++i; }
        }
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());
        _;
    }

    modifier nonReentrant() {
        require(_state.mutex == 1, "Nonreentrant");
        _state.mutex = 2;
        _;
        _state.mutex = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    /* === EVENTS === */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
}

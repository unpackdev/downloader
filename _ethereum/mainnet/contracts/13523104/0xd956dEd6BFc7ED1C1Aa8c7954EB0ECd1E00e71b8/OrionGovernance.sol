// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IOrionGovernance.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";

contract OrionGovernance is IOrionGovernance, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserData
    {
        uint56 balance;
        uint56 locked_balance;
    }

    ///////////////////////////////////////////////////
    //  Data fields
    //  NB: Only add new fields BELOW any fields in this section

    //  Must be 8-digit token
    IERC20 public staking_token_;

    //  Staking balances
    mapping(address => UserData) public balances_;

    //  Voting contract address (now just 1 voting contract supported)
    address public voting_contract_address_;

    //  Total balance
    uint56 public total_balance_;

    //  TODO: decrease writable uint256 count
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    //  Add new data fields there....
    //      ...

    //  End of data fields
    /////////////////////////////////////////////////////

    //  Initializer
    function initialize(address staking_token) public initializer {
        require(staking_token != address(0), "OGI0");
        OwnableUpgradeable.__Ownable_init();
        staking_token_ = IERC20(staking_token);
    }

    function setVotingContractAddress(address voting_contract_address) external onlyOwner
    {
        voting_contract_address_ = voting_contract_address;
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        //  return Math.min(block.timestamp, periodFinish);
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() override public view returns (uint256) {
        if (total_balance_ == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(uint(total_balance_))
        );
    }

    function earned(address account) override public view returns (uint256) {
        return uint(balances_[account].balance).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    //  Stake
    function stake(uint56 adding_amount) override public nonReentrant updateReward(msg.sender)
    {
        require(adding_amount > 0, "CNS0");
        staking_token_.safeTransferFrom(msg.sender, address(this), adding_amount);

        uint56 balance = balances_[msg.sender].balance;
        balance += adding_amount;
        require(balance >= adding_amount, "OF(1)");
        balances_[msg.sender].balance = balance;

        uint56 total_balance = total_balance_;
        total_balance += adding_amount;
        require(total_balance >= adding_amount, "OF(3)");  //  Maybe not needed
        total_balance_ = total_balance;

        emit Staked(msg.sender, uint256(adding_amount));
    }

    // Unstake
    function withdraw(uint56 removing_amount) override public nonReentrant updateReward(msg.sender) {
        _withdrawTo(msg.sender, removing_amount);
    }

    function withdrawTo(address to, uint56 removing_amount) override public nonReentrant updateReward(msg.sender) {
        _withdrawTo(to, removing_amount);
    }

    function _withdrawTo(address to, uint56 removing_amount) internal
    {
        require(removing_amount > 0, "CNW0");

        uint56 balance = balances_[msg.sender].balance;
        require(balance >= removing_amount, "CNW1");
        balance -= removing_amount;
        balances_[msg.sender].balance= balance;

        uint56 total_balance = total_balance_;
        require(total_balance >= removing_amount, "CNW2");
        total_balance -= removing_amount;
        total_balance_ = total_balance;

        uint56 locked_balance = balances_[msg.sender].locked_balance;
        require(locked_balance <= balance, "CNW3");
        staking_token_.safeTransfer(to, removing_amount);

        emit Withdrawn(msg.sender, uint256(removing_amount));
    }

    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        _getRewardTo(msg.sender);
    }

    function getRewardTo(address to) virtual override public nonReentrant updateReward(msg.sender) {
        _getRewardTo(to);
    }

    function _getRewardTo(address to) internal {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            staking_token_.safeTransfer(to, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override external nonReentrant updateReward(msg.sender) {
        _withdrawTo(msg.sender, balances_[msg.sender].balance);
        _getRewardTo(msg.sender);
    }

    function exitTo(address to) virtual override external nonReentrant updateReward(msg.sender) {
        _withdrawTo(to, balances_[msg.sender].balance);
        _getRewardTo(to);
    }

    function acceptNewLockAmount(
        address user,
        uint56 new_lock_amount
    ) external override onlyVotingContract
    {
        uint56 balance = balances_[user].balance;
        require(balance >= new_lock_amount, "Cannot lock");
        balances_[user].locked_balance = new_lock_amount;
    }

    function acceptLock(
        address user,
        uint56 lock_increase_amount
    )  external override onlyVotingContract
    {
        require(lock_increase_amount > 0, "Can't inc by 0");

        uint56 balance = balances_[user].balance;
        uint56 locked_balance = balances_[user].locked_balance;

        locked_balance += lock_increase_amount;
        require(locked_balance >= lock_increase_amount, "OF(4)");
        require(locked_balance <= balance, "can't lock more");

        balances_[user].locked_balance = locked_balance;
    }

    function acceptUnlock(
        address user,
        uint56 lock_decrease_amount
    )  external override onlyVotingContract
    {
        require(lock_decrease_amount > 0, "Can't dec by 0");

        uint56 locked_balance = balances_[user].locked_balance;
        require(locked_balance >= lock_decrease_amount, "Can't unlock more");

        locked_balance -= lock_decrease_amount;
        balances_[user].locked_balance = locked_balance;
    }

    //  Views
    function getBalance(address user) public view returns(uint56)
    {
        return balances_[user].balance;
    }

    function getLockedBalance(address user) public view returns(uint56)
    {
        return balances_[user].locked_balance;
    }

    function getTotalBalance() public view returns(uint56)
    {
        return total_balance_;
    }

    //  Root methods
    function notifyRewardAmount(uint256 reward, uint256 _rewardsDuration) external onlyOwner updateReward(address(0)) {
        require((_rewardsDuration> 1 days) && (_rewardsDuration < 365 days), "Incorrect rewards duration");
        rewardsDuration = _rewardsDuration;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = staking_token_.balanceOf(address(this)); //  TODO: review
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function emergencyAssetWithdrawal(address asset) external onlyOwner {
        IERC20 token = IERC20(asset);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    //  Modifiers
    modifier onlyVotingContract()
    {
        require(msg.sender == voting_contract_address_, "must be voting");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    //  Events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

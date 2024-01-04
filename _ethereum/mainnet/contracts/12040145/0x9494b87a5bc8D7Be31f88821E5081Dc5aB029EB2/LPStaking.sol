// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IMintable.sol";

contract LPStaking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Claimed(address indexed to, uint256 amount);

    IERC20 public stakeToken;
    IMintable public rewardToken;
    // reward rate per second
    uint256 public rewardRate;

    struct UserInfos {
        uint256 balance; // stacked balance
        uint256 pendingReward; // claimable reward
        uint256 rewardPerTokenPaid; // accumulated reward
    }

    struct PoolInfos {
        uint256 lastUpdateTimestamp;
        uint256 rewardPerTokenStored;
        uint256 totalValueStacked;
    }

    PoolInfos private _poolInfos;
    mapping(address => UserInfos) private _usersInfos; // Users infos per address

    uint256 public constant DURATION = 31 days;
    uint256 public constant REWARD_ALLOCATION = 16500 * 1e18;

    // Farming will be open on 15/03/2021 at 07:00:00 UTC
    uint256 public constant FARMING_START_TIMESTAMP = 1615791600;

    // No more rewards after 15/04/2021 at 07:00:00 UTC
    uint256 public constant FARMING_END_TIMESTAMP =
        FARMING_START_TIMESTAMP + DURATION;

    bool public farmingStarted = false;

    constructor(address stakeToken_, address rewardToken_) public {
        require(
            stakeToken_.isContract(),
            "LPStaking: stakeToken_ should be a contract"
        );
        require(
            stakeToken_.isContract(),
            "LPStaking: rewardToken_ should be a contract"
        );
        stakeToken = IERC20(stakeToken_);
        rewardToken = IMintable(rewardToken_);
        rewardRate = REWARD_ALLOCATION.div(DURATION);
    }

    function stake(uint256 amount_) external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        require(
            !address(msg.sender).isContract(),
            "LPStaking: Please use your individual account"
        );
        stakeToken.safeTransferFrom(msg.sender, address(this), amount_);
        _poolInfos.totalValueStacked = _poolInfos.totalValueStacked.add(
            amount_
        );

        // Add to balance
        _usersInfos[msg.sender].balance = _usersInfos[msg.sender].balance.add(
            amount_
        );

        emit Staked(msg.sender, amount_);
    }

    function withdraw(uint256 amount_) public nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        require(amount_ > 0, "LPStaking: Cannot withdraw 0");
        require(
            amount_ <= balanceOf(msg.sender),
            "LPStaking: Insufficent balance"
        );

        if (amount_ == 0) amount_ = _usersInfos[msg.sender].balance;
        // Reduce totalValue
        _poolInfos.totalValueStacked = _poolInfos.totalValueStacked.sub(
            amount_
        );
        // Reduce balance
        _usersInfos[msg.sender].balance = _usersInfos[msg.sender].balance.sub(
            amount_
        );

        stakeToken.safeTransfer(msg.sender, amount_);
        emit Withdrawn(msg.sender, amount_);
    }

    function claim() public nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        uint256 reward = _usersInfos[msg.sender].pendingReward;

        if (reward > 0) {
            // Reduce first
            _usersInfos[msg.sender].pendingReward = 0;

            // Send reward
            rewardToken.mint(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function withdrawAndClaim(uint256 amount_) public {
        withdraw(amount_);
        claim();
    }

    function exit() external {
        withdrawAndClaim(balanceOf(msg.sender));
    }

    function totalValue() external view returns (uint256) {
        return _poolInfos.totalValueStacked;
    }

    function balanceOf(address account_) public view returns (uint256) {
        return _usersInfos[account_].balance;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_poolInfos.totalValueStacked == 0) {
            return _poolInfos.rewardPerTokenStored;
        }

        return
            _poolInfos.rewardPerTokenStored.add(
                lastRewardTimestamp()
                    .sub(_poolInfos.lastUpdateTimestamp)
                    .mul(rewardRate) //rate per second
                    .mul(1e18)
                    .div(_poolInfos.totalValueStacked)
            );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, FARMING_END_TIMESTAMP);
    }

    function pendingReward(address account_) public view returns (uint256) {
        return
            _usersInfos[account_]
                .balance
                .mul(
                rewardPerToken().sub(_usersInfos[account_].rewardPerTokenPaid)
            )
                .div(1e18)
                .add(_usersInfos[account_].pendingReward);
    }

    function _updateReward(address account_) internal {
        _poolInfos.rewardPerTokenStored = rewardPerToken();
        _poolInfos.lastUpdateTimestamp = lastRewardTimestamp();
        if (account_ != address(0)) {
            _usersInfos[account_].pendingReward = pendingReward(account_);
            _usersInfos[account_].rewardPerTokenPaid = _poolInfos
                .rewardPerTokenStored;
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(
            FARMING_START_TIMESTAMP <= block.timestamp,
            "LPStaking: Please wait until farming started"
        );
        if (!farmingStarted) {
            farmingStarted = true;
            _poolInfos.lastUpdateTimestamp = block.timestamp;
        }
    }
}

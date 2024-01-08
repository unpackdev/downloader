//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./IStakingRewards.sol";

/// @title StakingRewards, A contract where users can stake a token X "stakingToken" and get Y..X..Z as rewards
/// @notice Based on https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol but better
contract StakingRewards is Ownable, ReentrancyGuard, IStakingRewards {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier notStopped {
        require(!isStopped, "Rewards have stopped");
        _;
    }

    modifier onlyRewardsPeriod {
        require(block.number < endBlock, "Rewards period ended");
        _;
    }

    struct RewardInfo {
        IERC20 rewardToken;
        uint256 lastRewardBlock; // Last block number that reward token distribution occurs.
        uint256 rewardPerBlock; // How many reward tokens to distribute per block.
        uint256 totalRewards;
        uint256 accTokenPerShare; // Accumulated token per share, times 1e18.
    }
    RewardInfo[] private rewardInfo;

    IERC20 public immutable stakingToken; // token to be staked for rewards

    uint256 public immutable startBlock; // block number when reward period starts
    uint256 public endBlock; // block number when reward period ends

    // how many blocks to wait after owner can reclaim unclaimed tokens
    uint256 public immutable bufferBlocks;

    // indicates that rewards have stopped forever and can't be extended anymore
    // also means that owner recovered all unclaimed rewards after a certain amount of bufferBlocks has passed
    // new users won't be able to deposit and everyone left can withdraw his/her stake
    bool public isStopped;

    mapping(address => uint256) private userAmount;
    mapping(uint256 => mapping(address => uint256)) private rewardDebt; // rewardDebt[rewardId][user] = N
    mapping(uint256 => mapping(address => uint256)) private rewardPaid; // rewardPaid[rewardId][user] = N

    EnumerableSet.AddressSet private pooledTokens;

    uint8 private constant MAX_POOLED_TOKENS = 5;

    constructor(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) {
        _startBlock = (_startBlock == 0) ? block.number : _startBlock;

        require(
            _endBlock > block.number && _endBlock > _startBlock,
            "Invalid end block"
        );

        stakingToken = IERC20(_stakingToken);
        startBlock = _startBlock;
        endBlock = _endBlock;
        bufferBlocks = _bufferBlocks;
    }

    /**
     * @notice Caller deposits the staking token to start earning rewards
     * @param _amount amount of staking token to deposit
     */
    function deposit(uint256 _amount)
        external
        override
        notStopped
        nonReentrant
    {
        updateAllRewards();

        uint256 _currentAmount = userAmount[msg.sender];
        uint256 _balanceBefore = stakingToken.balanceOf(address(this));

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _amount = stakingToken.balanceOf(address(this)) - _balanceBefore;

        uint256 _newUserAmount = _currentAmount + _amount;

        if (_currentAmount > 0) {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                uint256 _pending =
                    ((_currentAmount * _reward.accTokenPerShare) / 1e18) -
                        rewardDebt[i][msg.sender];

                rewardDebt[i][msg.sender] =
                    (_newUserAmount * _reward.accTokenPerShare) /
                    1e18;

                rewardPaid[i][msg.sender] += _pending;

                _reward.rewardToken.safeTransfer(msg.sender, _pending);
            }
        } else {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                rewardDebt[i][msg.sender] =
                    (_amount * _reward.accTokenPerShare) /
                    1e18;
            }
        }

        userAmount[msg.sender] = _newUserAmount;

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Caller withdraws the staking token and its pending rewards, if any
     * @param _amount amount of staking token to withdraw
     */
    function withdraw(uint256 _amount) external override nonReentrant {
        updateAllRewards();

        uint256 _currentAmount = userAmount[msg.sender];

        require(_currentAmount >= _amount, "withdraw: not good");

        uint256 newUserAmount = _currentAmount - _amount;

        if (!isStopped) {
            for (uint256 i = 0; i < rewardInfo.length; i++) {
                RewardInfo memory _reward = rewardInfo[i];

                uint256 _pending =
                    ((_currentAmount * _reward.accTokenPerShare) / 1e18) -
                        rewardDebt[i][msg.sender];

                rewardDebt[i][msg.sender] =
                    (newUserAmount * _reward.accTokenPerShare) /
                    1e18;

                rewardPaid[i][msg.sender] += _pending;

                _reward.rewardToken.safeTransfer(msg.sender, _pending);
            }
        }

        userAmount[msg.sender] = newUserAmount;

        stakingToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Caller withdraws tokens staked by user without caring about rewards
     */
    function emergencyWithdraw() external override nonReentrant {
        for (uint256 i = 0; i < rewardInfo.length; i++) {
            rewardDebt[i][msg.sender] = 0;
        }

        stakingToken.safeTransfer(msg.sender, userAmount[msg.sender]);
        userAmount[msg.sender] = 0;
        emit EmergencyWithdraw(msg.sender, userAmount[msg.sender]);
    }

    /**
     * @notice Caller claims its pending rewards without having to withdraw its stake
     */
    function claimRewards() external override notStopped nonReentrant {
        for (uint256 i = 0; i < rewardInfo.length; i++) _claimReward(i);
    }

    /**
     * @notice Caller claims a single pending reward without having to withdraw its stake
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function claimReward(uint256 _rid)
        external
        override
        notStopped
        nonReentrant
    {
        _claimReward(_rid);
    }

    /**
     * @notice Adds a reward token to the pool, only contract owner can call this
     * @param _rewardToken address of the ERC20 token
     * @param _totalRewards amount of total rewards to distribute from startBlock to endBlock
     */
    function add(IERC20 _rewardToken, uint256 _totalRewards)
        external
        override
        nonReentrant
        onlyOwner
        onlyRewardsPeriod
    {
        require(rewardInfo.length < MAX_POOLED_TOKENS, "Pool is full");
        _add(_rewardToken, _totalRewards);
    }

    /**
     * @notice Adds multiple reward tokens to the pool in a single call, only contract owner can call this
     * @param _rewardSettings array of struct composed of "IERC20 rewardToken" and "uint256 totalRewards"
     */
    function addMulti(RewardSettings[] memory _rewardSettings)
        external
        override
        nonReentrant
        onlyOwner
        onlyRewardsPeriod
    {
        require(
            rewardInfo.length + _rewardSettings.length < MAX_POOLED_TOKENS,
            "Pool is full"
        );
        for (uint8 i = 0; i < _rewardSettings.length; i++)
            _add(
                _rewardSettings[i].rewardToken,
                _rewardSettings[i].totalRewards
            );
    }

    /**
     * @notice Owner can recover any ERC20 that's not the staking token neither a pooledToken
     * @param _tokenAddress address of the ERC20 mistakenly sent to this contract
     * @param _tokenAmount amount to recover
     */
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        override
        onlyOwner
    {
        require(
            _tokenAddress != address(stakingToken) &&
                !pooledTokens.contains(_tokenAddress),
            "Cannot recover"
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Owner can recover rewards that's not been claimed after endBlock + bufferBlocks
     * @dev Warning: it will set isStopped to true, so no more deposits, extensions or rewards claim but only withdrawals
     */
    function recoverUnclaimedRewards() external override onlyOwner notStopped {
        require(
            block.number > endBlock + bufferBlocks,
            "Not allowed to reclaim"
        );
        isStopped = true;
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            IERC20 _token = IERC20(rewardInfo[i].rewardToken);
            uint256 _amount = _token.balanceOf(address(this));
            rewardInfo[i].lastRewardBlock = block.number;
            _token.safeTransfer(msg.sender, _amount);
            emit UnclaimedRecovered(address(_token), _amount);
        }
    }

    /**
     * @notice After a reward period has ended owner can decide to extend it by adding more rewards
     * @dev totalRewards will be distributed from block.number to newEndBlock
     * @param _newEndBlock block number when new rewards end
     * @param _newTotalRewards array of new total rewards for each pooled token
     */
    function extendRewards(
        uint256 _newEndBlock,
        uint256[] memory _newTotalRewards
    ) external override onlyOwner notStopped nonReentrant {
        require(block.number > endBlock, "Rewards not ended");
        require(_newEndBlock > block.number, "Invalid end block");
        require(
            _newTotalRewards.length == rewardInfo.length,
            "Pool length mismatch"
        );

        for (uint8 i = 0; i < _newTotalRewards.length; i++) {
            updateReward(i);
            uint256 _balanceBefore =
                IERC20(rewardInfo[i].rewardToken).balanceOf(address(this));
            IERC20(rewardInfo[i].rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _newTotalRewards[i]
            );
            _newTotalRewards[i] =
                IERC20(rewardInfo[i].rewardToken).balanceOf(address(this)) -
                _balanceBefore;
            uint256 _rewardPerBlock =
                _newTotalRewards[i] / (_newEndBlock - block.number);
            rewardInfo[i].rewardPerBlock = _rewardPerBlock;
            rewardInfo[i].totalRewards += _newTotalRewards[i];
        }

        endBlock = _newEndBlock;

        emit RewardsExtended(_newEndBlock);
    }

    /**
     * @notice Gets the number of pooled reward tokens in contract
     */
    function rewardsLength() external view override returns (uint256) {
        return rewardInfo.length;
    }

    /**
     * @notice Gets the amount of staked tokens for a given user
     * @param _user address of given user
     */
    function balanceOf(address _user) external view override returns (uint256) {
        return userAmount[_user];
    }

    /**
     * @notice Gets the total amount of staked tokens in contract
     */
    function totalSupply() external view override returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /**
     * @notice Caller can see pending rewards for a given reward id and user
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     * @param _user address of a user
     * @return amount of pending rewards
     */
    function getPendingRewards(uint256 _rid, address _user)
        external
        view
        override
        returns (uint256)
    {
        return _getPendingRewards(_rid, _user);
    }

    /**
     * @notice Caller can see pending rewards for a given user
     * @param _user address of a user
     * @return array of struct containing rewardToken and pendingReward
     */
    function getAllPendingRewards(address _user)
        external
        view
        override
        returns (PendingRewards[] memory)
    {
        PendingRewards[] memory _pendingRewards =
            new PendingRewards[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            _pendingRewards[i] = PendingRewards({
                rewardToken: rewardInfo[i].rewardToken,
                pendingReward: _getPendingRewards(i, _user)
            });
        }
        return _pendingRewards;
    }

    /**
     * @notice Caller can see pending rewards for a given user
     * @param _user address of a user
     * @return array of struct containing rewardToken and pendingReward
     */
    function earned(address _user)
        external
        view
        override
        returns (EarnedRewards[] memory)
    {
        EarnedRewards[] memory earnedRewards =
            new EarnedRewards[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            earnedRewards[i] = EarnedRewards({
                rewardToken: rewardInfo[i].rewardToken,
                earnedReward: rewardPaid[i][_user] +
                    _getPendingRewards(i, _user)
            });
        }
        return earnedRewards;
    }

    /**
     * @notice Caller can see total rewards for every pooled token
     * @return array of struct containing rewardToken and totalRewards
     */
    function getRewardsForDuration()
        external
        view
        override
        returns (RewardSettings[] memory)
    {
        RewardSettings[] memory _rewardSettings =
            new RewardSettings[](rewardInfo.length);
        for (uint8 i = 0; i < rewardInfo.length; i++) {
            _rewardSettings[i] = RewardSettings({
                rewardToken: rewardInfo[i].rewardToken,
                totalRewards: rewardInfo[i].totalRewards
            });
        }
        return _rewardSettings;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function updateReward(uint256 _rid) public {
        RewardInfo storage _reward = rewardInfo[_rid];

        if (block.number <= _reward.lastRewardBlock) {
            return;
        }
        uint256 _lpSupply = stakingToken.balanceOf(address(this));

        if (_lpSupply == 0) {
            _reward.lastRewardBlock = block.number;
            return;
        }

        uint256 _tokenReward = getMultiplier(_reward) * _reward.rewardPerBlock;

        _reward.accTokenPerShare += (_tokenReward * 1e18) / _lpSupply;

        _reward.lastRewardBlock = block.number;
    }

    /**
     * @notice Mass updates reward variables
     */
    function updateAllRewards() public {
        uint256 _length = rewardInfo.length;
        for (uint256 pid = 0; pid < _length; pid++) {
            updateReward(pid);
        }
    }

    /**
     * @notice Gets the correct multiplier of rewardPerBlock for a given RewardInfo
     */
    function getMultiplier(RewardInfo memory _reward)
        internal
        view
        returns (uint256 _multiplier)
    {
        uint256 _lastBlock =
            (block.number > endBlock) ? endBlock : block.number;
        _multiplier = (_lastBlock > _reward.lastRewardBlock)
            ? _lastBlock - _reward.lastRewardBlock
            : 0;
    }

    /**
     * @notice Pending rewards for a given reward id and user
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     * @param _user address of a user
     * @return amount of pending rewards
     */
    function _getPendingRewards(uint256 _rid, address _user)
        internal
        view
        returns (uint256)
    {
        if (isStopped) return 0;

        RewardInfo storage _reward = rewardInfo[_rid];

        uint256 _amount = userAmount[_user];
        uint256 _debt = rewardDebt[_rid][_user];

        uint256 _rewardPerBlock = _reward.rewardPerBlock;

        uint256 _accTokenPerShare = _reward.accTokenPerShare;

        uint256 _lpSupply = stakingToken.balanceOf(address(this));

        if (block.number > _reward.lastRewardBlock && _lpSupply != 0) {
            uint256 reward = getMultiplier(_reward) * _rewardPerBlock;
            _accTokenPerShare += ((reward * 1e18) / _lpSupply);
        }

        return ((_amount * _accTokenPerShare) / 1e18) - _debt;
    }

    /**
     * @notice Adds a reward token to the rewards pool
     * @param _rewardToken address of the ERC20 token
     * @param _totalRewards amount of total rewards to distribute from startBlock to endBlock
     */
    function _add(IERC20 _rewardToken, uint256 _totalRewards) internal {
        require(
            address(_rewardToken) != address(stakingToken),
            "rewardToken = stakingToken"
        );
        require(!pooledTokens.contains(address(_rewardToken)), "pool exists");

        uint256 _balanceBefore = _rewardToken.balanceOf(address(this));
        _rewardToken.safeTransferFrom(msg.sender, address(this), _totalRewards);
        _totalRewards = _rewardToken.balanceOf(address(this)) - _balanceBefore;

        require(_totalRewards != 0, "No rewards");

        uint256 _lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;

        pooledTokens.add(address(_rewardToken));

        uint256 _rewardPerBlock = _totalRewards / (endBlock - _lastRewardBlock);

        rewardInfo.push(
            RewardInfo({
                rewardToken: _rewardToken,
                rewardPerBlock: _rewardPerBlock,
                totalRewards: _totalRewards,
                lastRewardBlock: _lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    /**
     * @notice Caller claims a single pending reward without having to withdraw its stake
     * @dev _rid is the index of rewardInfo array
     * @param _rid reward id
     */
    function _claimReward(uint256 _rid) internal {
        updateReward(_rid);

        uint256 _amount = userAmount[msg.sender];

        uint256 _debt = rewardDebt[_rid][msg.sender];

        RewardInfo memory _reward = rewardInfo[_rid];

        uint256 pending = ((_amount * _reward.accTokenPerShare) / 1e18) - _debt;

        rewardPaid[_rid][msg.sender] += pending;

        rewardDebt[_rid][msg.sender] =
            (_amount * _reward.accTokenPerShare) /
            1e18;

        _reward.rewardToken.safeTransfer(msg.sender, pending);
    }
}

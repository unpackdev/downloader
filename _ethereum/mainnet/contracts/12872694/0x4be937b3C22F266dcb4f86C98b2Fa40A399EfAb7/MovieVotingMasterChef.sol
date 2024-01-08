// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./BasicMetaTransaction.sol";

contract MovieVotingMasterChef is BasicMetaTransaction, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    // Info of each user.
    struct UserInfo {
        uint256 amount; // how many Stars the user has provided.
        uint256 rewardDebt; // reward debt. See explaination below.
        uint256 penalizedRewards; // rewards that got penalized when users withdraw prematurely
        //
        // We do some fancy math here. Basically, any point in time, the amount of Stars
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accStarsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Stars to the pool. Here's what happens:
        //   1. The pool's `accStarsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Stars distribution occurs.
        uint256 accStarsPerShare; // Accumulated Stars per share, times ACC_STARS_PRECISION. See below.
        uint256 poolSupply; // the the total amount of Stars in the pool.
        uint256 rewardAmount; // the amount of Stars to give out as rewards.
        uint256 rewardAmountPerBlock; // the amount of Stars to give out as rewards per block.
        uint256 startBlock; // staking start block.
        uint256 endBlock; // staking end block.
    }

    bool public initialized;
    uint256 private constant ACC_STARS_PRECISION = 1e12;
    // The movie voting contract.
    address public movieVoting;
    // The Stars token.
    IERC20 public stars;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event RewardsCollected(address indexed user, uint256 indexed pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawPartial(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier onlyAdmin {
        require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
        _;
    }

    modifier isInitialized {
        require(initialized, "Not initialized");
        _;
    }

    /**
     * @dev Stores the Stars contract, and allows users with the admin role to
     * grant/revoke the admin role from other users.
     *
     * Params:
     * starsAddress: the address of the Stars contract.
     * _admin: the address of the first admin.
     */
    constructor(address starsAddress, address _admin) public {
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        stars = IERC20(starsAddress);
    }

    /**
     * @dev Sets the Movie Voting contract address.
     *
     * Params:
     * _movieVotingAddress: the Movie Voting contract address.
     *
     * Requirements:
     * - contract must not be initialized.
     */
    function init(address _movieVotingAddress) external onlyAdmin {
        require(!initialized, "Already initialized");
        movieVoting = _movieVotingAddress;
        _setupRole(ROLE_ADMIN, _movieVotingAddress);

        initialized = true;
    }

    /**
     * @dev Returns the number of pools there are for front-end.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Adds a new pool. Admin only.
     *
     * Params:
     * _startBlock: the staking start block.
     * _endBlock: the staking end block.
     * _rewardAmount: the total stars the distribute in this pool.
     * _withUpdate: whether or not to update all pools.
     *
     * Requirements:
     * - Start block number must be a future block.
     */
    function add(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardAmount,
        bool _withUpdate
    ) external onlyAdmin isInitialized {
        require(
            block.number < _startBlock,
            "Start block number must be a future block"
        );

        if (_withUpdate) {
            massUpdatePools();
        }
        stars.transferFrom(msgSender(), address(this), _rewardAmount);

        poolInfo.push(
            PoolInfo({
                lastRewardBlock: _startBlock,
                accStarsPerShare: 0,
                poolSupply: 0,
                rewardAmount: _rewardAmount,
                rewardAmountPerBlock: _rewardAmount.div(
                    _endBlock.sub(_startBlock)
                ),
                startBlock: _startBlock,
                endBlock: _endBlock
            })
        );
    }

    /**
     * @dev View function to see pending Stars on frontend.
     *
     * Params:
     * _pid: the pool id.
     * _user: address of the stars to view the pending rewards for.
     */
    function pendingStars(uint256 _pid, address _user)
        external
        view
        isInitialized
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (pool.poolSupply == 0 || block.number < pool.startBlock) {
            return 0;
        }

        uint256 currRateEndStarsPerShare = accStarsPerShareAtCurrRate(
            uint256(block.number).sub(pool.startBlock),
            pool.rewardAmountPerBlock,
            pool.poolSupply,
            pool.startBlock,
            pool.endBlock
        );
        uint256 currRateStartStarsPerShare = accStarsPerShareAtCurrRate(
            pool.lastRewardBlock.sub(pool.startBlock),
            pool.rewardAmountPerBlock,
            pool.poolSupply,
            pool.startBlock,
            pool.endBlock
        );
        uint256 starsReward = (
            currRateEndStarsPerShare.sub(currRateStartStarsPerShare)
        );

        uint256 pendingAccStarsPerShare = pool.accStarsPerShare.add(
            starsReward
        );
        return
            user
                .amount
                .mul(pendingAccStarsPerShare)
                .div(ACC_STARS_PRECISION)
                .sub(user.rewardDebt)
                .add(user.penalizedRewards);
    }

    /**
     * @dev An internal function to calculate the total accumulated Stars per
     * share, assuming the stars per share remained the same since staking
     * began.
     *
     * Params:
     * blocks: The number of blocks to calculate for.
     * rewardAmountPerBlock: amount of Stars to reward per block.
     * poolSupply: total number of Stars in the pool.
     * startBlock: the staking start block.
     * endBlock: the staking end block.
     */
    function accStarsPerShareAtCurrRate(
        uint256 blocks,
        uint256 rewardAmountPerBlock,
        uint256 poolSupply,
        uint256 startBlock,
        uint256 endBlock
    ) public pure returns (uint256) {
        if (blocks > endBlock.sub(startBlock)) {
            return
                rewardAmountPerBlock
                    .mul(endBlock.sub(startBlock))
                    .mul(ACC_STARS_PRECISION)
                    .div(poolSupply);
        } else {
            return
                blocks.mul(rewardAmountPerBlock).mul(ACC_STARS_PRECISION).div(
                    poolSupply
                );
        }
    }

    /**
     * @dev A function for the front-end to see information about the current
     rewards.
     * Params:
     * pid: The pool id.
     */
    function starsPerBlock(uint256 pid) external view returns (uint256 amount) {
        return poolInfo[pid].rewardAmountPerBlock;
    }

    /**
     * @dev Calculates the additional stars per share that have been accumulated
     * since lastRewardBlock, and updates accStarsPerShare and lastRewardBlock
     * accordingly.
     */
    function updatePool(uint256 _pid) public isInitialized {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.poolSupply != 0) {
            uint256 currRateEndStarsPerShare = accStarsPerShareAtCurrRate(
                uint256(block.number).sub(pool.startBlock),
                pool.rewardAmountPerBlock,
                pool.poolSupply,
                pool.startBlock,
                pool.endBlock
            );
            uint256 currRateStartStarsPerShare = accStarsPerShareAtCurrRate(
                pool.lastRewardBlock.sub(pool.startBlock),
                pool.rewardAmountPerBlock,
                pool.poolSupply,
                pool.startBlock,
                pool.endBlock
            );
            uint256 starsReward = (
                currRateEndStarsPerShare.sub(currRateStartStarsPerShare)
            );

            pool.accStarsPerShare = pool.accStarsPerShare.add(starsReward);
        }
        pool.lastRewardBlock = block.number;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public isInitialized {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Deposit stars for staking. The sender's information is updated accordingly.
     *
     * Params:
     * _pid: the pool id.
     * _amount: amount of Stars to deposit.
     * _staker: the staker's address.
     *
     * Requirements:
     * - the current block must have reached the pools start block.
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) external onlyAdmin isInitialized {
        PoolInfo storage pool = poolInfo[_pid];

        require(block.number >= pool.startBlock, "Deposit not started");

        UserInfo storage user = userInfo[_pid][_staker];
        updatePool(_pid);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.rewardDebt.add(
            (_amount.mul(pool.accStarsPerShare).div(ACC_STARS_PRECISION))
        );
        pool.poolSupply = pool.poolSupply.add(_amount);

        stars.safeTransferFrom(_staker, address(this), _amount);

        emit Deposit(_staker, _pid, _amount);
    }

    /**
     * @dev Withdraw all of the staker's stars from staking. The sender's information is updated accordingly.
     *
     * Params:
     * _pid: the pool id.
     * _staker: the staker's address.
     *
     * Requirements:
     * - the current block must have reached the pools start block.
     */
    function withdraw(uint256 _pid, address _staker)
        external
        onlyAdmin
        isInitialized
    {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            block.number > pool.endBlock,
            "Cannot withdraw before voting period ends"
        );
        UserInfo storage user = userInfo[_pid][_staker];

        updatePool(_pid);

        uint256 _amount = user.amount;
        uint256 _penalizedRewards = user.penalizedRewards;

        uint256 pending = user
        .amount
        .mul(pool.accStarsPerShare)
        .div(ACC_STARS_PRECISION)
        .sub(user.rewardDebt);

        user.amount = 0;
        user.rewardDebt = 0;
        user.penalizedRewards = 0;
        pool.poolSupply = pool.poolSupply.sub(_amount);

        safeStarsTransfer(_staker, pending.add(_amount).add(_penalizedRewards));

        emit Withdraw(_staker, _pid, _amount);
    }

    function withdrawPartial(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) external onlyAdmin isInitialized {
        PoolInfo storage pool = poolInfo[_pid];

        UserInfo storage user = userInfo[_pid][_staker];

        require(user.amount >= _amount, "Insufficient STARS to withdraw");

        updatePool(_pid);

        uint256 pending = user
        .amount
        .mul(pool.accStarsPerShare)
        .div(ACC_STARS_PRECISION)
        .sub(user.rewardDebt);

        uint256 oldUserAmount = user.amount;

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            safeStarsTransfer(_staker, _amount);
            user.penalizedRewards = user
            .penalizedRewards
            .mul(user.amount)
            .div(oldUserAmount)
            .add(pending.mul(user.amount).div(oldUserAmount));
            pool.poolSupply = pool.poolSupply.sub(_amount);
        }

        user.rewardDebt = (
            user.amount.mul(pool.accStarsPerShare).div(ACC_STARS_PRECISION)
        );

        emit WithdrawPartial(_staker, _pid, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards.
     *
     * Params:
     * _pid: the pool id.
     * _staker: the staker's address.
     *
     */
    function emergencyWithdraw(uint256 _pid, address _staker)
        external
        onlyAdmin
        isInitialized
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_staker];

        stars.safeTransfer(_staker, user.amount);

        pool.poolSupply = pool.poolSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(_staker, _pid, user.amount);
    }

    /**
     * @dev Safe Stars transfer function, just in case if rounding error causes
     * pool to not have enough Stars. Transaction gas fee on additional checks
     * will be more expensive than the possible rounding profit itself.
     *
     * Params:
     * _to: address to send Stars to.
     * _amount: amount of Stars to send.
     */
    function safeStarsTransfer(address _to, uint256 _amount) internal {
        uint256 starsBal = stars.balanceOf(address(this));
        if (_amount > starsBal) {
            stars.transfer(_to, starsBal);
        } else {
            stars.transfer(_to, _amount);
        }
    }
}

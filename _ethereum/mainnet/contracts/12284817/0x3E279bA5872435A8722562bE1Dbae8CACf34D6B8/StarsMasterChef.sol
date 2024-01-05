// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract StarsMasterChef is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Stars the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
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
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Stars to distribute per block.
        uint256 lastRewardBlock; // Last block number that Stars distribution occurs.
        uint256 accStarsPerShare; // Accumulated Stars per share, times 1e12. See below.
        uint256 poolSupply;
    }

    // The Stars token
    IERC20 public stars;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when Stars staking starts.
    uint256 public startBlock;
    bool public initialized;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Total Stars awarded per block on each of the 3 epochs
    uint256[3] public rewardAmounts;
    // The number of blocks since the starting block until each epoch ends
    uint256[3] public epochs;
    // The total number of stars distributed as rewards in each epoch
    uint256[3] public totalStarsPerEpoch;
    event RewardsCollected(address indexed user, uint256 indexed pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
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
     * grant/revoke the admin role from other users. Sets reward amounts and
     * epochs.
     *
     * Params:
     * starsAddress: the address of the Stars contract
     * _admin: the address of the first admin
     */
    constructor(
        address starsAddress,
        address _admin,
        uint256[3] memory _rewardAmounts,
        uint256[3] memory _epochs
    ) public {
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        require(
            _epochs[0] < _epochs[1] && _epochs[1] < _epochs[2],
            "invalid epochs"
        );

        stars = IERC20(starsAddress);
        rewardAmounts = _rewardAmounts;
        epochs = _epochs;

        totalStarsPerEpoch[0] = _rewardAmounts[0].mul(_epochs[0]);
        totalStarsPerEpoch[1] = _rewardAmounts[1].mul(
            _epochs[1].sub(_epochs[0])
        );
        totalStarsPerEpoch[2] = _rewardAmounts[2].mul(
            _epochs[2].sub(_epochs[1])
        );
    }

    /**
     * @dev Transfers 40 million ether and sets the startblock. Admin only
     *
     * Params:
     * _startBlock: the block number for staking to begin
     */
    function init(uint256 _startBlock) public onlyAdmin {
        require(!initialized, "Already initialized");
        stars.safeTransferFrom(
            msg.sender,
            address(this),
            totalStarsPerEpoch[0].add(totalStarsPerEpoch[1]).add(
                totalStarsPerEpoch[2]
            )
        );
        startBlock = _startBlock;
        initialized = true;
    }

    /**
     * @dev Returns the number of pools there are for front-end.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Adds a new pool. Admin only
     *
     * Params:
     * _allocPoint: the allocation points to be assigned to this pool
     * _lpToken: the token that this pool accepts
     * _withUpdate: whether or not to update all pools
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyAdmin isInitialized {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accStarsPerShare: 0,
                poolSupply: 0
            })
        );
    }

    /**
     * @dev Sets new pool. Admin only
     *
     * Params:
     * _pid: pool id
     * _allocPoint: the allocation points to be assigned to this pool
     * _withUpdate: whether or not to update all pools
     */
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyAdmin isInitialized {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev View function to see pending Stars on frontend.
     *
     * Params:
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

        if (pool.poolSupply == 0) {
            return 0;
        }

        uint256 currRateEndStarsPerShare =
            accStarsPerShareAtCurrRate(
                uint256(block.number).sub(startBlock),
                pool.poolSupply
            );
        uint256 currRateStartStarsPerShare =
            accStarsPerShareAtCurrRate(
                pool.lastRewardBlock.sub(startBlock),
                pool.poolSupply
            );
        uint256 starsReward =
            (currRateEndStarsPerShare.sub(currRateStartStarsPerShare))
                .mul(pool.allocPoint)
                .div(totalAllocPoint);

        uint256 pendingAccStarsPerShare =
            pool.accStarsPerShare.add(starsReward);
        return
            user.amount.mul(pendingAccStarsPerShare).div(1e12).sub(
                user.rewardDebt
            );
    }

    /**
     * @dev An internal function to calculate the total accumulated Stars per
     * share, assuming the stars per share remained the same since staking
     * began.
     *
     * Params:
     * blocks: The number of blocks to calculate for
     */
    function accStarsPerShareAtCurrRate(uint256 blocks, uint256 poolSupply)
        public
        view
        returns (uint256)
    {
        if (blocks > epochs[2]) {
            return
                totalStarsPerEpoch[0]
                    .add(totalStarsPerEpoch[1])
                    .add(totalStarsPerEpoch[2])
                    .mul(1e12)
                    .div(poolSupply);
        } else if (blocks > epochs[1]) {
            uint256 currTierRewards =
                (blocks.sub(epochs[1]).mul(rewardAmounts[2]));
            return
                totalStarsPerEpoch[0]
                    .add(totalStarsPerEpoch[1])
                    .add(currTierRewards)
                    .mul(1e12)
                    .div(poolSupply);
        } else if (blocks > epochs[0]) {
            uint256 currTierRewards =
                (blocks.sub(epochs[0]).mul(rewardAmounts[1]));
            return
                totalStarsPerEpoch[0].add(currTierRewards).mul(1e12).div(
                    poolSupply
                );
        } else {
            return blocks.mul(rewardAmounts[0]).mul(1e12).div(poolSupply);
        }
    }

    /**
     * @dev A function for the front-end to see information about the current
     rewards.
     */
    function starsPerBlock()
        public
        view
        isInitialized
        returns (uint256 amount)
    {
        uint256 blocks = uint256(block.number).sub(startBlock);
        if (blocks >= epochs[2]) {
            return 0;
        } else if (blocks >= epochs[1]) {
            return rewardAmounts[2];
        } else if (blocks >= epochs[0]) {
            return rewardAmounts[1];
        } else {
            return rewardAmounts[0];
        }
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
            uint256 currRateEndStarsPerShare =
                accStarsPerShareAtCurrRate(
                    uint256(block.number).sub(startBlock),
                    pool.poolSupply
                );
            uint256 currRateStartStarsPerShare =
                accStarsPerShareAtCurrRate(
                    pool.lastRewardBlock.sub(startBlock),
                    pool.poolSupply
                );
            uint256 starsReward =
                (currRateEndStarsPerShare.sub(currRateStartStarsPerShare))
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);

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
     * @dev Collect rewards owed.
     *
     * Params:
     * _pid: the pool id
     */
    function collectRewards(uint256 _pid) public isInitialized {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accStarsPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeStarsTransfer(msg.sender, pending);
            user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(1e12);
        }

        emit RewardsCollected(msg.sender, _pid);
    }

    /**
     * @dev Deposit stars for staking. The sender's pending rewards are
     * sent to the sender, and the sender's information is updated accordingly.
     *
     * Params:
     * _pid: the pool id
     * _amount: amount of Stars to deposit
     */
    function deposit(uint256 _pid, uint256 _amount) public isInitialized {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        uint256 pending =
            user.amount.mul(pool.accStarsPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeStarsTransfer(msg.sender, pending);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(1e12);
        pool.poolSupply = pool.poolSupply.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw Stars from the amount that the user is staking and collect
     * pending rewards.
     *
     * Params:
     * _pid: the pool id
     * _amount: amount of Stars to withdraw
     *
     * Requirements:
     * _amount is less than or equal to the amount of Stars the the user has
     * deposited to the contract
     */
    function withdraw(uint256 _pid, uint256 _amount) public isInitialized {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        uint256 pending =
            user.amount.mul(pool.accStarsPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeStarsTransfer(msg.sender, pending);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(1e12);
        pool.poolSupply = pool.poolSupply.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw(uint256 _pid) external isInitialized {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        pool.poolSupply = pool.poolSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @dev Safe Stars transfer function, just in case if rounding error causes
     * pool to not have enough Stars. Transaction gas fee on additional checks
     * will be more expensive than the possible rounding profit itself.
     *
     * Params:
     * _to: address to send Stars to
     * _amount: amount of Stars to send
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

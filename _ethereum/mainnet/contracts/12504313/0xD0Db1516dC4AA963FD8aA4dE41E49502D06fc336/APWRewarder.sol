// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./IRewarder.sol";

import "./BoringERC20.sol";
import "./BoringMath.sol";
import "./BoringOwnable.sol";

import "./MasterChefV2.sol";

// https://github.com/sushiswap/sushiswap/blob/master/contracts/mocks/ComplexRewarder.sol
contract APWRewarder is IRewarder, BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    address private MASTERCHEF_V2;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of SUSHI entitled to the user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of SUSHI to distribute per block.
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    /// @notice Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    uint256[] public poolIds;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 totalAllocPoint;

    IERC20 public rewardToken;
    uint256 public tokenPerBlock;
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    event TokenPerBlockSet(uint256 tokenPerBlock);
    event RewardClaimed(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event PoolAdded(uint256 indexed pid, uint256 allocPoint);
    event PoolSet(uint256 indexed pid, uint256 allocPoint);
    event PoolUpdated(
        uint256 indexed pid,
        uint64 lastRewardBlock,
        uint256 lpSupply,
        uint256 accSushiPerShare
    );

    /* Modifiers */

    modifier onlyMCV2 {
        require(msg.sender == MASTERCHEF_V2, "ERR_MCV2");
        _;
    }

    /**
     * @notice APWReward constructor
     * @param _MASTERCHEF_V2 Sushi MasterChefV2 address
     * @dev Requires further setup with setTokenPerBlock(uint256)
     */
    constructor(address _MASTERCHEF_V2, IERC20 _rewardToken) public {
        MASTERCHEF_V2 = _MASTERCHEF_V2;
        rewardToken = _rewardToken;
    }

    /* Sushi IRewarder overrides */

    function onSushiReward(
        uint256 _pid,
        address _user,
        address _to,
        uint256,
        uint256 _lpToken
    ) external override onlyMCV2 {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending;
        if (user.amount > 0) {
            pending = (user.amount.mul(pool.accSushiPerShare) /
                ACC_TOKEN_PRECISION)
                .sub(user.rewardDebt);
            rewardToken.safeTransfer(_to, pending);
        }
        user.amount = _lpToken;
        user.rewardDebt =
            _lpToken.mul(pool.accSushiPerShare) /
            ACC_TOKEN_PRECISION;
        emit RewardClaimed(_user, _pid, pending, _to);
    }

    function pendingTokens(
        uint256 _pid,
        address _user,
        uint256
    )
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(_pid, _user);
        return (_rewardTokens, _rewardAmounts);
    }

    /* Public */

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolIds.length;
    }

    /// @notice View function to see pending Token
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending SUSHI reward for a given user.
    function pendingToken(uint256 _pid, address _user)
        public
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply =
            MasterChefV2(MASTERCHEF_V2).lpToken(_pid).balanceOf(MASTERCHEF_V2);
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 sushiReward =
                blocks.mul(tokenPerBlock).mul(pool.allocPoint) /
                    totalAllocPoint;
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply
            );
        }
        pending = (user.amount.mul(accSushiPerShare) / ACC_TOKEN_PRECISION).sub(
            user.rewardDebt
        );
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables for all pools registered in the contract.
    function updateAllPools() public {
        uint256 len = poolIds.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(poolIds[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        require(pool.lastRewardBlock != 0, "ERR_INVALID_POOL");
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply =
                MasterChefV2(MASTERCHEF_V2).lpToken(pid).balanceOf(
                    MASTERCHEF_V2
                );
            if (lpSupply > 0) {
                uint256 blocks = block.number.sub(pool.lastRewardBlock);
                uint256 sushiReward =
                    blocks.mul(tokenPerBlock).mul(pool.allocPoint) /
                        totalAllocPoint;
                pool.accSushiPerShare = pool.accSushiPerShare.add(
                    (sushiReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128()
                );
            }
            pool.lastRewardBlock = block.number.to64();
            poolInfo[pid] = pool;
            emit PoolUpdated(
                pid,
                pool.lastRewardBlock,
                lpSupply,
                pool.accSushiPerShare
            );
        }
    }

    /* Admin control */

    function setTokenPerBlock(uint256 _tokenPerBlock) public onlyOwner {
        updateAllPools();
        tokenPerBlock = _tokenPerBlock;
        emit TokenPerBlockSet(_tokenPerBlock);
    }

    function withdraw(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Add a new LP to the pool.  Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _pid Pid on MCV2
    function addPool(uint256 allocPoint, uint256 _pid) public onlyOwner {
        require(poolInfo[_pid].lastRewardBlock == 0, "ERR_POOL_EXISTS");
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(allocPoint);

        poolInfo[_pid] = PoolInfo({
            allocPoint: allocPoint.to64(),
            lastRewardBlock: lastRewardBlock.to64(),
            accSushiPerShare: 0
        });
        poolIds.push(_pid);
        emit PoolAdded(_pid, allocPoint);
    }

    /// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        emit PoolSet(_pid, _allocPoint);
    }
}

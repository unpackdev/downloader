// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract CombMasterV21 is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. COMBs to distribute per block.
        uint256 lastRewardBlock; // Last block number that COMBs distribution occurs.
        uint256 accCombPerShare; // Accumulated COMBs per share, times 1e12. See below.
    }

    // The COMB TOKEN!
    IERC20 public comb;
    // COMB tokens created on first block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public lpTokenExistsInPool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when COMB mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(
            !lpTokenExistsInPool[address(_lpToken)],
            "MasterCheif: LP Token Address already exists in pool"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCombPerShare: 0
            })
        );
        lpTokenExistsInPool[address(_lpToken)] = true;
    }

    // Update the given pool's COMB allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }

    // View function to see pending COMBs on frontend.
    function pendingComb(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCombPerShare = pool.accCombPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 combReward =
                ((block.number - pool.lastRewardBlock) *
                    rewardPerBlock *
                    pool.allocPoint) / totalAllocPoint;
            accCombPerShare += ((combReward * 1e12) / lpSupply);
        }
        return (user.amount * accCombPerShare) / 1e12 - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 combReward =
            ((block.number - pool.lastRewardBlock) *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
        pool.accCombPerShare += ((combReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for COMB allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                ((user.amount * pool.accCombPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                safeCombTransfer(msg.sender, pending);
            }
            emit Harvest(msg.sender, _pid, user.amount);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount += _amount;
        }
        user.rewardDebt = (user.amount * pool.accCombPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                ((user.amount * pool.accCombPerShare) / 1e12) * user.rewardDebt;
            if (pending > 0) {
                safeCombTransfer(msg.sender, pending);
            }
        }
        user.rewardDebt = (user.amount * pool.accCombPerShare) / 1e12;
        emit Harvest(msg.sender, _pid, user.amount);
    }

    function harvestAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            harvest(pid);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            (user.amount * pool.accCombPerShare) / 1e12 - user.rewardDebt;
        if (pending > 0) {
            safeCombTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accCombPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe comb transfer function, just in case if rounding error causes pool to not have enough COMBs.
    function safeCombTransfer(address _to, uint256 _amount) internal {
        uint256 combBal = comb.balanceOf(address(this));
        if (_amount > combBal) {
            comb.transfer(_to, combBal);
        } else {
            comb.transfer(_to, _amount);
        }
    }
}

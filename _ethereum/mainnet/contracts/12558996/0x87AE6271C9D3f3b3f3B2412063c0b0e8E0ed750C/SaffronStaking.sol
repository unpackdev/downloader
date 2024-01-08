// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ISFIRewarder.sol";

contract SaffronERC20Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SFIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SFIs distribution occurs.
        uint256 accSFIPerShare; // Accumulated SFIs per share, times 1e12. See below.
    }
    // The SFI TOKEN!
    IERC20 public sfi;

    // SFI tokens created per block.
    uint256 public sfiPerBlock;

    uint256 public rewardEndBlock;

    address public rewardDistributor;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _sfi,
        address _rewardDistributor,
        uint256 _sfiPerBlock
    ) public {
        sfi = _sfi;
        rewardDistributor = _rewardDistributor;
        sfiPerBlock = _sfiPerBlock;
    }

    function updateRewardDistributor(address _newRewardDistributor) external onlyOwner {
        require(_newRewardDistributor != address(0), "invalid address");
        rewardDistributor = _newRewardDistributor;
    }

    function setRewardPerBlock(uint256 _sfiPerBlock) external onlyOwner {
        require(_sfiPerBlock > 0, "invalid sfiperblock");
        sfiPerBlock = _sfiPerBlock;
    }

    function setRewardEndBlock(uint256 _endblock) external onlyOwner {
        require(_endblock > 0, "invalid block number");
        rewardEndBlock = _endblock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, lastRewardBlock: block.number, accSFIPerShare: 0})
        );
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function pendingSFI(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSFIPerShare = pool.accSFIPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        uint256 currentBlock = block.number;
        if (rewardEndBlock != 0 && block.number >= rewardEndBlock) currentBlock = rewardEndBlock;

        if (currentBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = currentBlock.sub(pool.lastRewardBlock);
            uint256 sfiReward = multiplier.mul(sfiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSFIPerShare = accSFIPerShare.add(sfiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSFIPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentBlock = block.number;
        if (rewardEndBlock != 0 && block.number >= rewardEndBlock) currentBlock = rewardEndBlock;

        if (currentBlock <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }

        uint256 multiplier = currentBlock.sub(pool.lastRewardBlock);
        uint256 sfiReward = multiplier.mul(sfiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accSFIPerShare = pool.accSFIPerShare.add(sfiReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = currentBlock;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSFIPerShare).div(1e12).sub(user.rewardDebt);
            safeSFITransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSFIPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSFIPerShare).div(1e12).sub(user.rewardDebt);
        safeSFITransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSFIPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sfi transfer function, just in case if rounding error causes pool to not have enough SFIs.
    function safeSFITransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) ISFIRewarder(rewardDistributor).supplyRewards(_to, _amount);
    }
}

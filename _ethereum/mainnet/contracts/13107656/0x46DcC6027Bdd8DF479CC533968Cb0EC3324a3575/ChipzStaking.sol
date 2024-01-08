// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract ChipzStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken;           // Address of staking token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CHPZs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CHPZs distribution occurs.
        uint256 accChipzPerShare;   // Accumulated CHPZs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The CHPZ TOKEN!
    IERC20 public chipz;

    // CHPZ tokens created per block.
    uint256 public chipzPerBlock;
    // Bonus muliplier for early chipz makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // StakingWallet address
    address public stakingWallet;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocatison points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when staking starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetStakingWallet(address indexed user, address indexed stakingWallet);
    event UpdateEmissionRate(address indexed user, uint256 chipzPerBlock);

    constructor(
        IERC20 _chipz,
        address _stakingWallet,
        address _feeAddress,
        uint256 _chipzPerBlock,
        uint256 _startBlock
    ) {
        chipz = _chipz;
        stakingWallet = _stakingWallet;
        feeAddress = _feeAddress;
        chipzPerBlock = _chipzPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _StakingToken) {
        require(poolExistence[_StakingToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _stakingToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_stakingToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_stakingToken] = true;
        poolInfo.push(PoolInfo({
        stakingToken : _stakingToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accChipzPerShare : 0,
        depositFeeBP : _depositFeeBP
        }));
    }

    // Update the given pool's CHPZ allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CHPZs on frontend.
    function pendingChipz(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accChipzPerShare = pool.accChipzPerShare;
        uint256 tokenSupply = pool.stakingToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 chipzReward = multiplier.mul(chipzPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accChipzPerShare = accChipzPerShare.add(chipzReward.mul(1e12).div(tokenSupply));
        }
        return user.amount.mul(accChipzPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 tokenSupply = pool.stakingToken.balanceOf(address(this));
        if (tokenSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 chipzReward = multiplier.mul(chipzPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        chipz.transferFrom(stakingWallet, address(this), chipzReward);
        pool.accChipzPerShare = pool.accChipzPerShare.add(chipzReward.mul(1e12).div(tokenSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit staking tokens to Pool for CHPZ allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accChipzPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeChipzTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.stakingToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accChipzPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw staking tokens from Pool.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accChipzPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeChipzTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accChipzPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe chipz transfer function, just in case if rounding error causes pool to not have enough CHPZs.
    function safeChipzTransfer(address _to, uint256 _amount) internal {
        uint256 chipzBal = chipz.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > chipzBal) {
            transferSuccess = chipz.transfer(_to, chipzBal);
        } else {
            transferSuccess = chipz.transfer(_to, _amount);
        }
        require(transferSuccess, "safeChipzTransfer: transfer failed");
    }

    // Update stakingWallet address by the owner.
    function setStakingWalletAddress(address _stakingWallet) public onlyOwner {
        stakingWallet = _stakingWallet;
        emit SetStakingWallet(msg.sender, _stakingWallet);
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //CHipz has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _chipzPerBlock) public onlyOwner {
        massUpdatePools();
        chipzPerBlock = _chipzPerBlock;
        emit UpdateEmissionRate(msg.sender, _chipzPerBlock);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;




















// File: contracts/MasterChef.sol

import "./IBGStakingReserve.sol";




pragma solidity ^0.6.12;

contract IBGETHMasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public totalRewardPaid;
    uint256 public MAX_REWARDS =  9352007939594230000000000;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; 
       
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. IBGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that IBGs distribution occurs.
        uint256 accIBGPerShare; // Accumulated IBGs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    // The IBG TOKEN!
    IERC20 public ibg;
    // Dev address.
    address public devaddr;
    address public productwallet;
    // IBG tokens created per block.
    uint256 public ibgPerBlock;
    // Bonus muliplier for early ibg makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    uint256 private MAX_FEE = 500; //5%

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when IBG mining starts.
    uint256 public startBlock;

    IBGStakingReserve public iBGStakingReserve;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _ibg,
        address _devaddr,
        address _feeAddress,
        uint256 _ibgPerBlock,
        uint256 _startBlock,
        IBGStakingReserve _iBGStakingReserve
    ) public {
        ibg = _ibg;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        ibgPerBlock = _ibgPerBlock;
        startBlock = _startBlock;
        iBGStakingReserve = _iBGStakingReserve;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= MAX_FEE, 'invalid fee');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accIBGPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    // Update the given pool's IBG allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= MAX_FEE, 'invalid fee');
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

    // View function to see pending IBGs on frontend.
    function pendingIBG(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accIBGPerShare = pool.accIBGPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ibgReward = multiplier.mul(ibgPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accIBGPerShare = accIBGPerShare.add(ibgReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accIBGPerShare).div(1e12).sub(user.rewardDebt);
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
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ibgReward = multiplier.mul(ibgPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        refillIBG(devaddr,ibgReward.div(10));
        refillIBG(address(this), ibgReward);

        pool.accIBGPerShare = pool.accIBGPerShare.add(ibgReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }






    // Deposit LP tokens to MasterChef for IBG allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accIBGPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeIBGTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 preBal = pool.lpToken.balanceOf(address(this)); // safe deflationary tokens
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterBal  = pool.lpToken.balanceOf(address(this)); // safe deflationary tokens
            _amount = afterBal.sub(preBal);
            
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accIBGPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, 'withdraw: not good');
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accIBGPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeIBGTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accIBGPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe ibg transfer function, just in case if rounding error causes pool to not have enough IBGs.
    function safeIBGTransfer(address _to, uint256 _amount) internal {
        uint256 ibgBal = ibg.balanceOf(address(this));
        if (_amount > ibgBal) {
            ibg.transfer(_to, ibgBal);
        } else {
            ibg.transfer(_to, _amount);
        }

    }



    function refillIBG(address _to, uint256 _amount) internal {

         if(totalRewardPaid.add(_amount) <= MAX_REWARDS){
            iBGStakingReserve.withdrawIBG(_to, _amount);
            totalRewardPaid = totalRewardPaid.add(_amount);
         }

    }


    // Update dev address by the previous dev.

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, 'dev: wut?');
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, 'setFeeAddress: FORBIDDEN');
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ibgPerBlock) public onlyOwner {
        massUpdatePools();
        ibgPerBlock = _ibgPerBlock;
    }
}
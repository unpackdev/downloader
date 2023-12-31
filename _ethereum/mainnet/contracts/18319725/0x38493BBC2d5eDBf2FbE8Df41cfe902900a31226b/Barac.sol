// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IAddressContract.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol"; 
import "./ERC20VotesUpgradeable.sol";
import { SafeMathUpgradeable } from  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";



contract Barac is ERC20Upgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    
    // libraries
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // state vars
    // scarab token
    IERC20Upgradeable public SCARAB;
    // admin address
    address public adminAddress;
    // Bonus muliplier for early SCARAB makers.
    uint256 public BONUS_MULTIPLIER;
    // // Number of top staker stored
    // uint256 public topStakerNumber;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when reward distribution start.
    uint256 public startBlock;
    // total SCARAB staked
    uint256 public totalSCARABStaked;
    // total SCARAB used for purchase land
    uint256 public totalScarabUsedForPurchase;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // //highest staked users
    // struct HighestAstaStaker {
    //     uint256 deposited;
    //     address addr;
    // }
   
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewarbaracDebt; // Reward debt in SCARAB.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken;       // Address of LP token contract.//
        uint256 allocPoint;              // How many allocation points assigned to this pool.
        uint256 lastRewardBlock;         // Last block number that Scarab distribution occurs.
        uint256 accScarabPerShare;       // Accumulated Scarabs per share, times 1e12. See below.
        uint256 lastTotalScarabReward;   // last total rewards
        uint256 lastScarabRewardBalance; // last Scarab rewards tokens
        uint256 totalScarabReward;       // total Scarab rewards tokens
    }

    // events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event AdminUpdated(address newAdmin);


    function initialize(IERC20Upgradeable _scarab, address _adminAddress, uint256 _startBlock) external initializer {
        __ERC20_init_unchained("BARACS", "BARACS");
        __ERC20Permit_init("BARACS");
        __ERC20Votes_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        require(_adminAddress != address(0), "initialize: Zero address");
        SCARAB = _scarab;
        adminAddress = _adminAddress;
        startBlock = _startBlock;
        BONUS_MULTIPLIER = 1;
    }

    function setContractAddresses(IAddressContract _contractFactory) external onlyOwner {
        SCARAB =  IERC20Upgradeable(_contractFactory.getScarab());
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20Upgradeable _lpToken, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accScarabPerShare: 0,
            lastTotalScarabReward: 0,
            lastScarabRewardBalance: 0,
            totalScarabReward: 0
        }));
    }

    // Update the given pool's SCARAB allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Deposit SCARAB tokens to MasterChef.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {

            uint256 scarabReward = user.amount.mul(pool.accScarabPerShare).div(1e12).sub(user.rewarbaracDebt);
            pool.lpToken.safeTransfer(msg.sender, scarabReward);
            pool.lastScarabRewardBalance = pool.lpToken.balanceOf(address(this)).sub(totalSCARABStaked.sub(totalScarabUsedForPurchase));
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        totalSCARABStaked = totalSCARABStaked.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewarbaracDebt = user.amount.mul(pool.accScarabPerShare).div(1e12);
        // addHighestStakedUser(_pid, user.amount, msg.sender);
        _mint(msg.sender,_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Earn SCARAB tokens to MasterChef.
    function claimSCARAB(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        
        uint256 scarabReward = user.amount.mul(pool.accScarabPerShare).div(1e12).sub(user.rewarbaracDebt);
        pool.lpToken.safeTransfer(msg.sender, scarabReward);
        pool.lastScarabRewardBalance = pool.lpToken.balanceOf(address(this)).sub(totalSCARABStaked.sub(totalScarabUsedForPurchase));
        
        user.rewarbaracDebt = user.amount.mul(pool.accScarabPerShare).div(1e12);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        uint256 scarabReward = user.amount.mul(pool.accScarabPerShare).div(1e12).sub(user.rewarbaracDebt);
        pool.lpToken.safeTransfer(msg.sender, scarabReward);
        pool.lastScarabRewardBalance = pool.lpToken.balanceOf(address(this)).sub(totalSCARABStaked.sub(totalScarabUsedForPurchase));

        user.amount = user.amount.sub(_amount);
        totalSCARABStaked = totalSCARABStaked.sub(_amount);
        user.rewarbaracDebt = user.amount.mul(pool.accScarabPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        // removeHighestStakedUser(_pid, user.amount, msg.sender);
        _burn(msg.sender,_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe SCARAB transfer function to admin.
    function accessSCARABTokens(uint256 _pid, address _to, uint256 _amount) external {
        require(msg.sender == adminAddress, "sender must be admin address");
        require(totalSCARABStaked.sub(totalScarabUsedForPurchase) >= _amount, "Amount must be less than staked SCARAB amount");
        PoolInfo storage pool = poolInfo[_pid];
        uint256 ScarabBal = pool.lpToken.balanceOf(address(this));
        if (_amount > ScarabBal) {
            require(pool.lpToken.transfer(_to, ScarabBal), "err in transfer");
            totalScarabUsedForPurchase = totalScarabUsedForPurchase.add(ScarabBal);
            emit EmergencyWithdraw(_to, _pid, ScarabBal);
        } else {
            require(pool.lpToken.transfer(_to, _amount), "err in transfer");
            totalScarabUsedForPurchase = totalScarabUsedForPurchase.add(_amount);
            emit EmergencyWithdraw(_to, _pid, _amount);
        }
    }

    // Update admin address by the previous admin.
    function admin(address _adminAddress) external {
        require(_adminAddress != address(0), "admin: Zero address");
        require(msg.sender == adminAddress, "admin: wut?");
        adminAddress = _adminAddress;
        emit AdminUpdated(_adminAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending SCARABs on frontend.
    function pendingSCARAB(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accScarabPerShare = pool.accScarabPerShare;
        uint256 lpSupply = totalSCARABStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rewardBalance = pool.lpToken.balanceOf(address(this)).sub(totalSCARABStaked.sub(totalScarabUsedForPurchase));
            uint256 _totalReward = rewardBalance.sub(pool.lastScarabRewardBalance);
            accScarabPerShare = accScarabPerShare.add(_totalReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accScarabPerShare).div(1e12).sub(user.rewarbaracDebt);
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
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 rewardBalance = pool.lpToken.balanceOf(address(this)).sub(totalSCARABStaked.sub(totalScarabUsedForPurchase));
        uint256 _totalReward = pool.totalScarabReward.add(rewardBalance.sub(pool.lastScarabRewardBalance));
        pool.lastScarabRewardBalance = rewardBalance;
        pool.totalScarabReward = _totalReward;
        
        uint256 lpSupply = totalSCARABStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            pool.accScarabPerShare = 0;
            pool.lastTotalScarabReward = 0;
            user.rewarbaracDebt = 0;
            pool.lastScarabRewardBalance = 0;
            pool.totalScarabReward = 0;
            return;
        }
        
        uint256 reward = _totalReward.sub(pool.lastTotalScarabReward);
        pool.accScarabPerShare = pool.accScarabPerShare.add(reward.mul(1e12).div(lpSupply));
        pool.lastTotalScarabReward = _totalReward;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to >= _from) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else {
            return _from.sub(_to);
        }
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if(from == address(0) || to == address(0)){
            super._beforeTokenTransfer(from, to, amount);
        }else{
            revert("Non transferable token");
        }
    }

    function _delegate(address delegator, address delegatee) internal override {
        // require(!checkHighestStaker(0, delegator),"Top staker cannot delegate");
        super._delegate(delegator,delegatee);
    }

    function clock() public view  override returns (uint48) {
        return SafeCastUpgradeable.toUint48(block.timestamp);
    }

    function CLOCK_MODE() public view override returns (string memory) {
        require(clock() == block.timestamp, "ERC20Votes: broken clock mode");
        return "mode=blocktimestamp&from=default";
    }

}
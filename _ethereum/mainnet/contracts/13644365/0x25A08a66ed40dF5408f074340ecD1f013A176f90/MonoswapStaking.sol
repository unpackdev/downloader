// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./MonoToken.sol";
import "./console.sol";

// MonoswapStaking is the master of Mono. He can make Mono and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MONO is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MonoswapStaking is Initializable, OwnableUpgradeable, ERC1155HolderUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastRewardBlock; // Last reward block.
        uint256 oldReward; // Old pool's reward. 
        //
        // We do some fancy math here. Basically, any point in time, the amount of MONOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMonoPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMonoPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC1155 lpToken; // Address of LP token contract.
        uint256 lpTokenId; // Id of LP token.
        uint256 stakedAmount; // Total LP tokens that the pool has.
        uint256 allocPoint; // How many allocation points assigned to this pool. MONOs to distribute per block.
        uint256 lastRewardBlock; // Last block number that MONOs distribution occurs.
        uint256 accMonoPerShare; // Accumulated MONOs per share, times 1e12. See below.
        address[] users; // List of user address.
        uint256 usersLen; // Length of user addresses.
        bool bActive; 
    }
    // The MONO TOKEN!
    MonoToken public mono;
    // MONO tokens created per reward period.
    uint256 public monoPerPeriod;
    // Dev address.
    address public devaddr;
    // Block numbers per reward period.
    uint256 public blockPerPeriod;
    // Decay rate per period
    uint256 public decay; // times 1e12
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // Current Period.
    uint256 public currentPeriod;
    mapping(uint256 => uint256) public ratios;
    uint256 public startBlock;
    // MONO tokens created per reward block.
    uint256 public monoPerBlock;
    bool unlocked;
    // Total minted MONO amount.
    uint256 public totalMonoMinted;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event SetMonoPerPeriod(uint256 monoPerPeriod);
    event SetDev(address devAddr);

    function initialize(
        MonoToken _mono,
        uint256 _monoPerPeriod,
        uint256 _blockPerPeriod,
        uint256 _decay
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        __ERC1155Holder_init();
        mono = _mono;
        monoPerPeriod = _monoPerPeriod;
        blockPerPeriod = _blockPerPeriod;
        monoPerBlock = monoPerPeriod.div(blockPerPeriod);
        decay = _decay;
        startBlock = block.number;
        currentPeriod = 0;
        ratios[currentPeriod] = 1e12;
        totalAllocPoint = 0;
        unlocked = true;
        devaddr = msg.sender;
    }

    modifier validPool(uint256 _pid) {
        require(_pid < poolInfo.length, "MonoswapStaking: pool not exist");
        _;
    }

    modifier lock() {
        require(unlocked == true, 'MonoswapStaking: locked');
        unlocked = false;
        _;
        unlocked = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function config() external view returns (uint256 _decay, uint256 _blockPerPeriod, uint256 _monoPerPeriod) {
        return (decay, blockPerPeriod, monoPerPeriod);
    }

    function usersOfPool(uint pid) external view returns (address[] memory) {
        return poolInfo[pid].users;
    }

    function setMonoPerPeriod(uint256 _monoPerPeriod) public onlyOwner {
        monoPerPeriod = _monoPerPeriod;
        monoPerBlock = monoPerPeriod.div(blockPerPeriod);
        emit SetMonoPerPeriod(_monoPerPeriod);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC1155 _lpToken,
        uint256 _lpTokenId
    ) public onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(!(pool.bActive && pool.lpToken == _lpToken && pool.lpTokenId == _lpTokenId), "MonoswapStaking: same lp token with same id");
        }
        massUpdatePools();
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lpTokenId: _lpTokenId,
                stakedAmount: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMonoPerShare: 0,
                users: new address[](0),
                usersLen: 0,
                bActive: true
            })
        );
    }

    // Update the given pool's MONO allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward periods over the given _from to _to block. times 1e6
    function getPeriods(uint256 _from, uint256 _to)
        public
        view
        returns (uint256, uint256)
    {
        return (_from.sub(startBlock).div(blockPerPeriod),
            _to.sub(startBlock).div(blockPerPeriod));
    }

    function updateRatios(uint256 blockNumber) public {
        uint256 endPeriod = blockNumber.sub(startBlock).div(blockPerPeriod);
        uint256 ratio = ratios[currentPeriod];
        while (currentPeriod < endPeriod) {
            ratio = ratio.mul(decay).div(1e12);
            currentPeriod += 1;
            ratios[currentPeriod] = ratio;
        }
    }

    // View function to see pending MONOs on frontend.
    function pendingMono(uint256 _pid, address _user)
        external
        view
        validPool(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMonoPerShare = pool.accMonoPerShare;
        uint256 stakedAmount = pool.stakedAmount;
        if (block.number >= pool.lastRewardBlock && stakedAmount != 0 && user.amount != 0) {
            if (pool.bActive == true) {
                (uint256 startPeriod, ) = getPeriods(pool.lastRewardBlock, block.number);
                uint256 ratio;
                if (startPeriod <= currentPeriod) {
                    ratio = ratios[startPeriod];
                } else {
                    uint256 index = currentPeriod;
                    ratio = ratios[index];
                    while (index < startPeriod) {
                        ratio = ratio.mul(decay).div(1e12);
                        index += 1;
                    }
                }
                uint256 monoReward = calcReward(pool.lastRewardBlock, block.number, ratio, pool.allocPoint);
                if (user.oldReward > 0) {
                    monoReward = monoReward.add(user.oldReward.mul(stakedAmount).mul(1e12).div(user.amount));
                }
                accMonoPerShare = accMonoPerShare.add(
                    monoReward.div(stakedAmount)
                );
            }
        }
        return (user.amount.mul(accMonoPerShare).mul(90)/1e14).sub(user.rewardDebt); // 90% to user
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (pool.bActive)
                updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakedAmount = pool.stakedAmount;
        if (stakedAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        (uint256 startPeriod, ) = getPeriods(pool.lastRewardBlock, block.number);
        updateRatios(block.number);
        uint256 monoReward = calcReward(pool.lastRewardBlock, block.number, ratios[startPeriod], pool.allocPoint);
        uint256 userReward = monoReward.mul(90)/1e14; // 90% to user
        
        if (monoReward.div(stakedAmount) != 0 && monoReward.div(1e12) != 0) {
            _mint(devaddr, monoReward.div(1e12).sub(userReward));
            _mint(address(this), userReward);
            pool.accMonoPerShare = pool.accMonoPerShare.add(
                monoReward.div(stakedAmount)
            );
        }
        
        pool.lastRewardBlock = block.number;
    }

    // Stop pool.
    function stopPool(uint256 _pid) public onlyOwner validPool(_pid) {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        pool.bActive = false;
        totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
    }

    // Migrate pool, move lp tokens and rewards from the old pool. 
    function migratePool(uint256 _oldPid, uint256 _newPid) public validPool(_oldPid) validPool(_newPid) {
        PoolInfo storage oldPool = poolInfo[_oldPid];
        PoolInfo storage newPool = poolInfo[_newPid];
        require(oldPool.bActive == false && newPool.bActive == true, "MonoswapStaking: wrong pools");
        require(oldPool.lpToken == newPool.lpToken && oldPool.lpTokenId == newPool.lpTokenId, "MonoswapStaking: different token pools");
        updatePool(_newPid);
        uint256 len = newPool.usersLen;
        for (uint256 uid = 0; uid < len; uid++) { 
            UserInfo storage newUser = userInfo[_newPid][newPool.users[uid]];
            newUser.oldReward = newUser.oldReward.add(newUser.amount.mul(newPool.accMonoPerShare).div(1e12).sub(newUser.rewardDebt));
            newUser.lastRewardBlock = block.number;
            newUser.rewardDebt = newUser.amount.mul(newPool.accMonoPerShare).div(1e12);
        }
        len = oldPool.usersLen;
        uint256 newAccMonoPerShare = newPool.accMonoPerShare;
        for (uint256 uid = 0; uid < len; uid++) { 
            UserInfo storage oldUser = userInfo[_oldPid][oldPool.users[uid]];
            UserInfo storage newUser = userInfo[_newPid][oldPool.users[uid]];
            newPool.stakedAmount = newPool.stakedAmount.add(oldUser.amount);
            if (newUser.amount == 0) { // if oldUser doesn't exist in newPool
                newPool.users.push(oldPool.users[uid]);
                newPool.usersLen++;
            }
            newUser.amount = newUser.amount.add(oldUser.amount);
            newUser.oldReward = newUser.oldReward.add(oldUser.amount.mul(oldPool.accMonoPerShare).div(1e12).sub(oldUser.rewardDebt));
            newUser.rewardDebt = newUser.amount.mul(newAccMonoPerShare).div(1e12);
            newUser.lastRewardBlock = block.number;
            oldUser.amount = 0;
        }
        oldPool.users = new address[](0);
        oldPool.stakedAmount = 0;
    }

    // Deposit LP tokens to MonoswapStaking for MONO allocation.
    function deposit(uint256 _pid, uint256 _amount) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.bActive == true, "MonoswapStaking: stopped pool");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 accMonoPerShare = pool.accMonoPerShare;
            uint256 pending = (user.amount.mul(accMonoPerShare).mul(90)/1e14).sub(user.rewardDebt); // 90% to user
            if (user.oldReward > 0) {
                pending = pending.add(user.oldReward);
                user.oldReward = 0;
            }
            if (pending > 0)
                safeMonoTransfer(msg.sender, pending);
        } else {
            pool.users.push(msg.sender);
            pool.usersLen++;
        }

        // Effects
        pool.stakedAmount = pool.stakedAmount.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accMonoPerShare).mul(90)/1e14;
        user.lastRewardBlock = block.number;

        safeLPTransfer(pool.lpToken, pool.lpTokenId, address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MonoswapStaking.
    function withdraw(uint256 _pid, uint256 _amount) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: insufficient amount");
        if (pool.bActive == true) {
            updatePool(_pid);
        }
        uint256 accMonoPerShare = pool.accMonoPerShare;
        uint256 pending = (user.amount.mul(accMonoPerShare).mul(90)/1e14).sub(user.rewardDebt); // 90% to user
        if (user.oldReward > 0) {
            pending = pending.add(user.oldReward);
            user.oldReward = 0;
        }
        if (pending > 0)
            safeMonoTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accMonoPerShare).mul(90)/1e14;
        user.lastRewardBlock = block.number;
        if (user.amount == 0) {
            uint256 len = pool.usersLen;
            for (uint256 uid = 0; uid < len; uid++) {
                if (pool.users[uid] == msg.sender) {
                    pool.users[uid] = pool.users[len-1];
                    pool.users.pop();
                    pool.usersLen--;
                    break;
                }
            }
        }
        pool.stakedAmount = pool.stakedAmount.sub(_amount);
        safeLPTransfer(pool.lpToken, pool.lpTokenId, address(this), address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount != 0, "emergencywithdraw: zero amount");
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.stakedAmount = pool.stakedAmount.sub(amount);
        safeLPTransfer(pool.lpToken, pool.lpTokenId, address(this), address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Safe mono transfer function, just in case if rounding error causes pool to not have enough MONOs.
    function safeMonoTransfer(address _to, uint256 _amount) internal {
        uint256 monoBal = mono.balanceOf(address(this));
        if (_amount > monoBal) {
            mono.transfer(_to, monoBal);
        } else {
            mono.transfer(_to, _amount);
        }
    }

    // Safe lp token transfer function, just in case if rounding error causes pool to not have enough MONOs.
    function safeLPTransfer(IERC1155 _lpToken, uint256 _lpTokenId, address _from, address _to, uint256 _amount) internal lock {
        require(_from == address(this) || _to == address(this), "transfer: wrong condition");
        uint256 balanceIn0 = _lpToken.balanceOf(address(this), _lpTokenId);
        _lpToken.safeTransferFrom(
            _from,
            _to,
            _lpTokenId,
            _amount,
            ""
        );
        uint256 balanceIn1 = _lpToken.balanceOf(address(this), _lpTokenId);
        if (_to == address(this)) { // receive
            require(balanceIn1.sub(balanceIn0) == _amount, "MonoswapStaking: not equal"); 
        } else { // send
           uint256 amountOut = balanceIn0.sub(balanceIn1);
           require(amountOut == _amount, "MonoswapStaking: not equal");
        }  
    }

    function getMultiplier(uint256 _from, uint256 _to, uint256 _ratio) 
        public
        view
        returns (uint256 multiplier) {
        if (_from >= _to) return 0;

        (uint256 startPeriod, uint256 endPeriod) = getPeriods(_from, _to);
        uint256 from = _from.sub(startBlock);
        uint256 to = _to.sub(startBlock);
        if (from % blockPerPeriod != 0) {
            startPeriod += 1;
            multiplier = multiplier.add((startPeriod.mul(blockPerPeriod) < to ? startPeriod.mul(blockPerPeriod) : to).sub(from).mul(_ratio));
            _ratio = startPeriod <= currentPeriod ? ratios[startPeriod] : _ratio.mul(decay).div(1e12);
        }
        uint256 index = startPeriod;
        while (index < endPeriod) {
            multiplier = multiplier.add(_ratio.mul(blockPerPeriod));
            index += 1;
            _ratio = index <= currentPeriod ? ratios[index] : _ratio.mul(decay).div(1e12);
        }
        if (startPeriod <= endPeriod) 
            multiplier = multiplier.add(to.sub(endPeriod.mul(blockPerPeriod)).mul(_ratio));
    }

    function calcReward(uint256 _fromBlock, uint256 _toBlock, uint256 _ratio, uint256 _allocPoint)
        public
        view
        returns (uint256)
    {
        uint256 multiplier = getMultiplier(_fromBlock, _toBlock, _ratio);
        return multiplier.mul(monoPerBlock).mul(_allocPoint).div(totalAllocPoint);
    }

    // Update dev address by only owner
    function setDev(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
        emit SetDev(_devaddr);
    }
    function _mint(address _to, uint256 _amount) internal {
        mono.mint(_to, _amount);
        totalMonoMinted += _amount; // safe ops because max supply is a safe int
    }
}

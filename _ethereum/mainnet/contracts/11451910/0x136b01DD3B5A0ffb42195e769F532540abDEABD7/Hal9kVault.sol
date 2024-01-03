pragma solidity 0.6.12;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./INBUNIERC20.sol";
import "./IHAL9KNFTPool.sol";
import "./console.sol";

// HAL9K Vault distributes fees equally amongst staked pools
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Hal9kVault is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many  tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HAL9Ks
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHal9kPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws  tokens to a pool. Here's what happens:
        //   1. The pool's `accHal9kPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of  token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. HAL9Ks to distribute per block.
        uint256 accHal9kPerShare; // Accumulated HAL9Ks per share, times 1e12. See below.
        bool withdrawable; // Is this pool withdrawable?
        mapping(address => mapping(address => uint256)) allowance;
    }

    // The HAL9k TOKEN!
    INBUNIERC20 public hal9k;

    // Dev address.
    address public devaddr;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    //// pending rewards awaiting anyone to massUpdate
    uint256 public pendingRewards;
    uint256 public contractStartBlock;
    uint256 public epochCalculationStartBlock;
    uint256 public cumulativeRewardsSinceStart;
    uint256 public rewardsInThisEpoch;
    uint256 public epoch;

    function getUserInfo(uint256 _pid, address _userAddress) external view returns (uint256 stakedAmount) {
        return userInfo[_pid][_userAddress].amount;
    }

    event NftPoolChanged(
        address indexed newAddress,
        address indexed oldAddress
    );

    IHAL9KNFTPool public _hal9kNftPool;

    function setNftPoolAddress(address hal9kNftPool) public onlyOwner {
        address oldAddress = address(_hal9kNftPool);
        _hal9kNftPool = IHAL9KNFTPool(hal9kNftPool);

        emit NftPoolChanged(hal9kNftPool, oldAddress);
    }

    // Returns fees generated since start of this contract
    function averageFeesPerBlockSinceStart()
        external
        view
        returns (uint256 averagePerBlock)
    {
        averagePerBlock = cumulativeRewardsSinceStart
            .add(rewardsInThisEpoch)
            .div(block.number.sub(contractStartBlock));
    }

    // Returns averge fees in this epoch
    function averageFeesPerBlockEpoch()
        external
        view
        returns (uint256 averagePerBlock)
    {
        averagePerBlock = rewardsInThisEpoch.div(
            block.number.sub(epochCalculationStartBlock)
        );
    }

    // For easy graphing historical epoch rewards
    mapping(uint256 => uint256) public epochRewards;

    //Starts a new calculation epoch
    // Because averge since start will not be accurate
    function startNewEpoch() public {
        require(
            epochCalculationStartBlock + 50000 < block.number,
            "New epoch not ready yet"
        ); // About a week
        epochRewards[epoch] = rewardsInThisEpoch;
        cumulativeRewardsSinceStart = cumulativeRewardsSinceStart.add(
            rewardsInThisEpoch
        );
        rewardsInThisEpoch = 0;
        epochCalculationStartBlock = block.number;
        ++epoch;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 startTime);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 _pid,
        uint256 value
    );

    function initialize(
        INBUNIERC20 _hal9k,
        IHAL9KNFTPool hal9kNftPool,
        address _devaddr,
        address superAdmin
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        DEV_FEE = 724;
        hal9k = _hal9k;
        devaddr = _devaddr;
        _hal9kNftPool = hal9kNftPool;
        contractStartBlock = block.number;
        _superAdmin = superAdmin;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setHal9kAddress(address _hal9k) public onlyOwner {
        hal9k = INBUNIERC20(_hal9k);
    }

    // Add a new token pool. Can only be called by the owner.
    // Note contract owner is meant to be a governance contract allowing HAL9K governance consensus
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        bool _withdrawable
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Error pool already added");
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                accHal9kPerShare: 0,
                withdrawable: _withdrawable
            })
        );
    }

    // Update the given pool's HAL9Ks allocation point. Can only be called by the owner.
    // Note contract owner is meant to be a governance contract allowing HAL9K governance consensus

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's ability to withdraw tokens
    // Note contract owner is meant to be a governance contract allowing HAL9K governance consensus
    function setPoolWithdrawable(uint256 _pid, bool _withdrawable)
        public
        onlyOwner
    {
        poolInfo[_pid].withdrawable = _withdrawable;
    }

    // Sets the dev fee for this contract
    // defaults at 7.24%
    // Note contract owner is meant to be a governance contract allowing HAL9K governance consensus
    uint16 DEV_FEE;

    function setDevFee(uint16 _DEV_FEE) public onlyOwner {
        require(_DEV_FEE <= 1000, "Dev fee clamped at 10%");
        DEV_FEE = _DEV_FEE;
    }

    uint256 pending_DEV_rewards;

    function getPendingDevFeeRewards() public view returns (uint256) {
        return pending_DEV_rewards;
    }

    // View function to see pending HAL9Ks on frontend.
    function pendingHal9k(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHal9kPerShare = pool.accHal9kPerShare;

        return user.amount.mul(accHal9kPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 allRewards;
        for (uint256 pid = 0; pid < length; ++pid) {
            allRewards = allRewards.add(updatePool(pid));
        }

        pendingRewards = pendingRewards.sub(allRewards);
    }

    // ----
    // Function that adds pending rewards, called by the HAL9K token.
    // ----
    uint256 private hal9kBalance;

    function addPendingRewards(uint256 _) public {
        uint256 newRewards = hal9k.balanceOf(address(this)).sub(hal9kBalance);

        if (newRewards > 0) {
            hal9kBalance = hal9k.balanceOf(address(this)); // If there is no change the balance didn't change
            pendingRewards = pendingRewards.add(newRewards);
            rewardsInThisEpoch = rewardsInThisEpoch.add(newRewards);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid)
        internal
        returns (uint256 hal9kRewardWhole)
    {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            // avoids division by 0 errors
            return 0;
        }
        hal9kRewardWhole = pendingRewards // Multiplies pending rewards by allocation point of this pool and then total allocation
            .mul(pool.allocPoint) // getting the percent of total pending rewards this pool should get
            .div(totalAllocPoint); // we can do this because pools are only mass updated
        uint256 hal9kRewardFee = hal9kRewardWhole.mul(DEV_FEE).div(10000);
        uint256 hal9kRewardToDistribute = hal9kRewardWhole.sub(hal9kRewardFee);

        pending_DEV_rewards = pending_DEV_rewards.add(hal9kRewardFee);

        pool.accHal9kPerShare = pool.accHal9kPerShare.add(
            hal9kRewardToDistribute.mul(1e12).div(tokenSupply)
        );
    }

    // Deposit  tokens to HAL9KVault for HAL9K allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        massUpdatePools();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(_pid, msg.sender);

        //Transfer in the amounts from user
        // save gas
        if (_amount > 0) {
            pool.token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accHal9kPerShare).div(1e12);
        if (_amount > 0) _hal9kNftPool.doHal9kStaking(msg.sender, _amount, block.timestamp);
        emit Deposit(msg.sender, _pid, _amount, block.timestamp);
    }

    // Test coverage
    // [x] Does user get the deposited amounts?
    // [x] Does user that its deposited for update correcty?
    // [x] Does the depositor get their tokens decreased
    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) public {
        // requires no allowances
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositFor];

        massUpdatePools();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(_pid, _depositFor); // Update the balances of person that amount is being deposited for

        if (_amount > 0) {
            pool.token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount); // This is depositedFor address
        }

        user.rewardDebt = user.amount.mul(pool.accHal9kPerShare).div(1e12); /// This is deposited for address
        if (_amount > 0) _hal9kNftPool.doHal9kStaking(_depositFor, _amount, block.timestamp);
        emit Deposit(_depositFor, _pid, _amount, block.timestamp);
    }

    // Test coverage
    // [x] Does allowance update correctly?
    function setAllowanceForPoolToken(
        address spender,
        uint256 _pid,
        uint256 value
    ) public {
        PoolInfo storage pool = poolInfo[_pid];
        pool.allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, _pid, value);
    }

    // Test coverage
    // [x] Does allowance decrease?
    // [x] Do oyu need allowance
    // [x] Withdraws to correct address
    function withdrawFrom(
        address owner,
        uint256 _pid,
        uint256 _amount
    ) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            pool.allowance[owner][msg.sender] >= _amount,
            "withdraw: insufficient allowance"
        );
        pool.allowance[owner][msg.sender] = pool.allowance[owner][msg.sender]
            .sub(_amount);
        _withdraw(_pid, _amount, owner, msg.sender);
    }

    // Withdraw  tokens from HAL9KVault.
    function withdraw(uint256 _pid, uint256 _amount) public {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
    }

    // Low level withdraw function
    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address from,
        address to
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
        UserInfo storage user = userInfo[_pid][from];
        require(user.amount >= _amount, "withdraw: not good");

        massUpdatePools();
        updateAndPayOutPending(_pid, from); // Update balances of from this is not withdrawal but claiming HAL9K farmed

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(to), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accHal9kPerShare).div(1e12);

        if (_amount > 0) _hal9kNftPool.withdrawLP(msg.sender, _amount);
        emit Withdraw(to, _pid, _amount);
    }

    function updateAndPayOutPending(uint256 _pid, address from) internal {
        UserInfo storage user = userInfo[_pid][from];

        if (user.amount == 0) return;
        PoolInfo storage pool = poolInfo[_pid];

        uint256 pending = user.amount.mul(pool.accHal9kPerShare).div(1e12).sub(
            user.rewardDebt
        );

        if (pending > 0) {
            safeHal9kTransfer(from, pending);
        }
    }

    // function that lets owner/governance contract
    // approve allowance for any token inside this contract
    // This means all future UNI like airdrops are covered
    // And at the same time allows us to give allowance to strategy contracts.
    // Upcoming cYFI etc vaults strategy contracts will  se this function to manage and farm yield on value locked
    function setStrategyContractOrDistributionContractAllowance(
        address tokenAddress,
        uint256 _amount,
        address contractAddress
    ) public onlySuperAdmin {
        require(
            isContract(contractAddress),
            "Recipent is not a smart contract, BAD"
        );
        require(
            block.number > contractStartBlock.add(95_000),
            "Governance setup grace period not over"
        );
        IERC20(tokenAddress).approve(contractAddress, _amount);
    }

    function isContract(address addr) public returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.withdrawable, "Withdrawing from this pool is disabled");
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeHal9kTransfer(address _to, uint256 _amount) internal {
        if (_amount == 0) return;

        uint256 hal9kBal = hal9k.balanceOf(address(this));
        if (_amount > hal9kBal) {
            hal9k.transfer(_to, hal9kBal);
            hal9kBalance = hal9k.balanceOf(address(this));
        } else {
            hal9k.transfer(_to, _amount);
            hal9kBalance = hal9k.balanceOf(address(this));
        }
        transferDevFee();
    }

    function transferDevFee() public {
        if (pending_DEV_rewards == 0) return;
        uint256 hal9kBal = hal9k.balanceOf(address(this));
        if (pending_DEV_rewards > hal9kBal) {
            hal9k.transfer(devaddr, hal9kBal);
            hal9kBalance = hal9k.balanceOf(address(this));
        } else {
            hal9k.transfer(devaddr, pending_DEV_rewards);
            hal9kBalance = hal9k.balanceOf(address(this));
        }
        pending_DEV_rewards = 0;
    }

    function setDevFeeReciever(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    address private _superAdmin;

    event SuperAdminTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    function superAdmin() public view returns (address) {
        return _superAdmin;
    }

    modifier onlySuperAdmin() {
        require(
            _superAdmin == _msgSender(),
            "Super admin : caller is not super admin."
        );
        _;
    }

    function burnSuperAdmin() public virtual onlySuperAdmin {
        emit SuperAdminTransfered(_superAdmin, address(0));
        _superAdmin = address(0);
    }

    function newSuperAdmin(address newOwner) public virtual onlySuperAdmin {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit SuperAdminTransfered(_superAdmin, newOwner);
        _superAdmin = newOwner;
    }
}

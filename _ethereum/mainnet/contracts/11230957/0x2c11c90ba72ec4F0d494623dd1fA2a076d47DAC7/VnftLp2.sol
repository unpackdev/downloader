/**
 *Submitted for verification at Etherscan.io on 2020-08-26
 */

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ERC20.sol";

import "./IVNFT.sol";

contract VnftLp2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Muse
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMusePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMusePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 currentPoint;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. MUSE to distribute per block.
        uint256 lastRewardBlock; // Last block number that MUSE distribution occurs.
        uint256 accMusePerShare; // Accumulated MUSE per share, times 1e12. See below.
    }

    // The vNFTs
    IVNFT public vnft;

    // Block number when bonus MUSE period ends.
    uint256 public bonusEndBlock;
    // MUSE tokens created per block.
    uint256 public pointsPerBlock;
    // Bonus muliplier for early MUSE makers.
    uint256 public constant BONUS_MULTIPLIER = 2;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MUSE mining starts.
    uint256 public startBlock;
    uint256 public pointStack;
    uint256 public vnftPrice = 400 * 10**18;

    mapping(uint256 => uint256) public vnftRedeemed;

    mapping(address => uint256) public waitingPoints;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Redeem(address indexed user, uint256 indexed pid, uint256 newvnftid);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(uint256 _pointsPerBlock, address _vnft) public {
        pointsPerBlock = _pointsPerBlock;
        vnft = IVNFT(_vnft);
        // bonusEndBlock = block.number.add(46523);
        bonusEndBlock = block.number +6800; //Initial Bonus is available for 1 day
        // startBlock = block.number;
        startBlock = block.number - 1; 
    
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMusePerShare: 0
            })
        );
    }

    // Update the given pool's MUSE allocation point. Can only be called by the owner.
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

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending Muse on frontend.
    function pendingPoints(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // if the staker doesn't own an nft then return 0 reward.
        if (vnft.balanceOf(_user) == 0) {
            return 0;
        } else {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][_user];
            uint256 accMusePerShare = pool.accMusePerShare;
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (block.number > pool.lastRewardBlock && lpSupply != 0) {
                uint256 multiplier = getMultiplier(
                    pool.lastRewardBlock,
                    block.number
                );
                uint256 museReward = multiplier
                    .mul(pointsPerBlock)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                accMusePerShare = accMusePerShare.add(
                    museReward.mul(1e12).div(lpSupply)
                );
            }
            return
                user
                    .amount
                    .mul(accMusePerShare)
                    .div(1e12)
                    .sub(user.rewardDebt)
                    .add(waitingPoints[_user]);
        }
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
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 museReward = multiplier
            .mul(pointsPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pointStack = pointStack.add(museReward);
        pool.accMusePerShare = pool.accMusePerShare.add(
            museReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Muse allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        // require to own at least one vNFT
        require(
            vnft.balanceOf(msg.sender) > 0,
            "You must own at least 1 vNFT to stake"
        );
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accMusePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            pointStack = pointStack.sub(pending);
            waitingPoints[msg.sender] = waitingPoints[msg.sender].add(pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accMusePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function redeem(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // if he doesn't own a vNFT when withdrawing, send him stake without rewards
        require(vnft.balanceOf(msg.sender) != 0, "You don't have any vnft");
        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accMusePerShare).div(1e12).sub(user.rewardDebt);

        require(pending + waitingPoints[msg.sender] >= vnftPrice, "You don't have enough points to redeem");
        // here mints nft
        vnft.mint(msg.sender);
        uint256 newvnftid = vnft.tokenOfOwnerByIndex(
            address(msg.sender),
            vnft.balanceOf(address(msg.sender)) - 1
        );
        vnftRedeemed[newvnftid] = block.number;
        waitingPoints[msg.sender] = waitingPoints[msg.sender].add(pending).sub(
            vnftPrice
        );
        user.rewardDebt = user.amount.mul(pool.accMusePerShare).div(1e12);
        emit Redeem(msg.sender, _pid, newvnftid);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        waitingPoints[msg.sender] = 0;
    }

    function setVnftPrice(uint256 _vnftPrice) public onlyOwner {
        vnftPrice = _vnftPrice * 10**18;
    }
}

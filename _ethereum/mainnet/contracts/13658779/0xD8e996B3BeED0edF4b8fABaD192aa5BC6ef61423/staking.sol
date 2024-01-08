// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// Adapted from SushiSwap's MasterChef contract
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract GNstaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.

        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakableToken; // Address of staking token contract.
        uint256 allocPoint; // How many gn to distribute per block.
        uint256 lastRewardBlock;
        uint256 accgnPerShare; // Accumulated gn per share, times 100. See below.
    }

    // gn Address
    IERC20 public gn;

    // Amount of gn allocated to pool per block
    uint256 gnPerBlock;
    // Bonus end block.
    uint256 public bonusEndBlock;
    // Bonus multiplier for the OGs
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocatuion  points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // start block
    uint256 public startBlock;

    // Make sure this is not a duplicate pool
    mapping(IERC20 => bool) public supportedToken;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor() public {
        gn = IERC20(0xc5019E129b75D380d3d837B8e609dEc6c8f5d044);
        gnPerBlock = 0;
        startBlock = block.number;
        bonusEndBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token or LP to the pool. Can only be called by the owner.
    // DO NOT add the same LP or token more than once. Rewards will be messed up if you do.

    function add(
        uint256 _allocPoint,
        IERC20 _stakableToken,
        bool _withUpdate
    ) public onlyOwner {
        // Each stakable token can only be added once.
        require(!supportedToken[_stakableToken], "add: duplicate token");
        supportedToken[_stakableToken] = true;

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                stakableToken: _stakableToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accgnPerShare: 0
            })
        );
    }

    // Update the given pool's gn allocation pointpercentage. Can only be called by the owner.
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

    // View function to see pending gn on frontend.
    function pendingGN(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accgnPerShare = pool.accgnPerShare;
        uint256 stakedSupply = pool.stakableToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakedSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 gnReward =
                multiplier.mul(gnPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );

            accgnPerShare = accgnPerShare.add(
                gnReward.mul(1e12).div(stakedSupply)
            );
        }
        return
            user.amount.mul(accgnPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 stakedSupply = pool.stakableToken.balanceOf(address(this));
        if (stakedSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 gnReward =
            multiplier.mul(gnPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        pool.accgnPerShare = pool.accgnPerShare.add(
            gnReward.mul(1e12).div(stakedSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Claim all if no amount specified, or Deposit new LP/SAS.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        // this is claim
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accgnPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeGNtransfer(msg.sender, pending);
            }
        } /// Deposit
        if (_amount > 0) {
            uint256 beforeAmount = pool.stakableToken.balanceOf(address(this));
            pool.stakableToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            uint256 _addAmt =
                pool.stakableToken.balanceOf(address(this)).sub(beforeAmount);

            user.amount = user.amount.add(_addAmt);
        }
        user.rewardDebt = user.amount.mul(pool.accgnPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw or Claim gn/LP/SaS tokens from FluxCampacitor.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accgnPerShare).div(1e12).sub(
                user.rewardDebt
            ); // Claim first all that is pending
        if (pending > 0) {
            safeGNtransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            // Remove stake
            user.amount = user.amount.sub(_amount);
            pool.stakableToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accgnPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.stakableToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe gn transfer function, just in case of rounding error causes pool to not have enough gn.
    function safeGNtransfer(address _to, uint256 _amount) internal {
        uint256 gnBal = gn.balanceOf(address(this));
        if (_amount > gnBal) {
            gn.transfer(_to, gnBal);
        } else {
            gn.transfer(_to, _amount);
        }
    }

    function updateGNPerBlock(uint256 _gnPerBlock)
        external
        onlyOwner
        returns (bool)
    {
        gnPerBlock = _gnPerBlock;
        return true;
    }

    function getGNBalance() external view returns (uint256) {
        uint256 gnBalance = gn.balanceOf(address(this));
        return gnBalance;
    }

    function getStaked(uint256 _pid, address)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 stakedamount = user.amount;
        return stakedamount;
    }
}

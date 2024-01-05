// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IErc20WithDecimals.sol";
import "./XPoolHandler.sol";

// Amplify is XFIT distibutor.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once XFIT is sufficiently
// distributed and the community can show to govern itself.

contract XFai is XPoolHandler, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastDepositedBlock;
        //
        // We do some fancy math here. Basically, any point in time, the amount of XFITs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accXFITPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accXFITPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }


    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IERC20 inputToken; // Token in which Single sided liquidity can be provided
        IXPriceOracle xPoolOracle;
        uint256 allocPoint; // How many allocation points assigned to this pool. XFITs to distribute per block.
        uint256 lastRewardBlock; // Last block number that XFITs distribution occurs.
        uint256 accXFITPerShare; // Accumulated XFITs per share, times 1e18. See below.
    }

    // The XFIT TOKEN!
    IERC20 public immutable XFIT;

    // Dev address.
    address public devaddr;
    // Block number when bonus XFIT period ends.
    uint256 public immutable bonusEndBlock;
    // XFIT tokens distributed per block.
    uint256 public XFITPerBlock;

    uint256 public totalLiquidity;

    // Bonus muliplier for early XFIT farmers.
    uint256 public constant BONUS_MULTIPLIER = 2;

    uint256 public constant REWARD_FACTOR = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when XFIT mining starts.
    uint256 public immutable startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _XFIT,
        address _devaddr,
        uint256 _XFITPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _xFitThreeshold,
        uint256 _fundsSplitFactor
    ) XPoolHandler(_xFitThreeshold, _fundsSplitFactor) {
        XFIT = _XFIT;
        devaddr = _devaddr;
        XFITPerBlock = _XFITPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        IERC20 _lpToken,
        IERC20 _inputToken,
        IXPriceOracle _xPoolOracle,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                inputToken: _inputToken,
                xPoolOracle: _xPoolOracle,
                allocPoint: 0,
                lastRewardBlock: lastRewardBlock,
                accXFITPerShare: 0
            })
        );
    }

    function _setInternal(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function _getNormalisedLiquidity(IERC20 _inputToken, uint256 _lpAmount)
        internal
        view
        returns (uint256 normalizedAmount)
    {
        normalizedAmount = _lpAmount;
        if (IErc20WithDecimals(address(_inputToken)).decimals() == 6) {
            normalizedAmount = _lpAmount.mul(1e6);
        }
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

    // View function to see pending XFITs on frontend.
    function pendingXFIT(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXFITPerShare = pool.accXFITPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 XFITReward =
                multiplier.mul(XFITPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accXFITPerShare = accXFITPerShare.add(
                XFITReward.mul(1e18).div(lpSupply)
            );
        }
        return user.amount.mul(accXFITPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function massUpdateAllocationPoints() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (lpSupply == 0) {
                return;
            }
            if (totalLiquidity == 0) {
                _setInternal(pid, 0, false);
            } else {
                _setInternal(
                    pid,
                    _getNormalisedLiquidity(pool.inputToken, lpSupply)
                        .mul(1e18)
                        .div(totalLiquidity),
                    false
                );
            }
        }
    }

    function depositLPWithToken(
        uint256 _pid,
        uint256 _amount,
        uint256 _minPoolTokens
    ) public whenNotPaused {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        (uint256 lpTokensBought, uint256 fundingRaised) =
            poolLiquidity(
                address(pool.inputToken),
                address(pool.lpToken),
                address(pool.xPoolOracle),
                _amount,
                _minPoolTokens
            );
        // Continous funding to devAddress
        if (fundingRaised > 0) {
            pool.inputToken.safeTransfer(devaddr, fundingRaised);
        }
        _depositInternal(_pid, lpTokensBought, false);
    }

    // Deposit LP tokens to Amplify for XFIT allocation.
    function depositLP(uint256 _pid, uint256 _amount) public whenNotPaused {
        massUpdatePools();
        _depositInternal(_pid, _amount, true);
    }

    function withdrawLPWithToken(uint256 _pid, uint256 _amount)
        public
        whenNotPaused
    {
        massUpdatePools();
        uint256 actualWithdrawAmount = _withdrawInternal(_pid, _amount, false);
        PoolInfo storage pool = poolInfo[_pid];
        redeemLPTokens(address(pool.lpToken), actualWithdrawAmount);
    }

    // Withdraw LP tokens from Amplify.
    function withdrawLP(uint256 _pid, uint256 _amount) public whenNotPaused {
        massUpdatePools();
        _withdrawInternal(_pid, _amount, true);
    }

    function _depositInternal(
        uint256 _pid,
        uint256 _amount,
        bool withLPTokens
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accXFITPerShare).div(1e18).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeXFITTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            if (withLPTokens == true) {
                pool.lpToken.safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _amount
                );
            }
            user.amount = user.amount.add(_amount);
        }
        totalLiquidity = totalLiquidity.add(
            _getNormalisedLiquidity(pool.inputToken, _amount)
        );
        massUpdateAllocationPoints();
        user.rewardDebt = user.amount.mul(pool.accXFITPerShare).div(1e18);
        user.lastDepositedBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function _withdrawInternal(
        uint256 _pid,
        uint256 _amount,
        bool withLPTokens
    ) internal returns (uint256) {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending =
            user.amount.mul(pool.accXFITPerShare).div(1e18).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeXFITTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            require(
                block.number >= user.lastDepositedBlock.add(10),
                "Withdraw: Can only withdraw after 10 blocks"
            );
            user.amount = user.amount.sub(_amount);
            if (withLPTokens == true) {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        }
        totalLiquidity = totalLiquidity.sub(
            _getNormalisedLiquidity(pool.inputToken, _amount)
        );
        massUpdateAllocationPoints();
        user.rewardDebt = user.amount.mul(pool.accXFITPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
        return _amount;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (totalLiquidity > 0) {
            _setInternal(
                _pid,
                _getNormalisedLiquidity(pool.inputToken, lpSupply)
                    .mul(1e18)
                    .div(totalLiquidity),
                false
            );
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 XFITReward =
            multiplier.mul(XFITPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        XFIT.transfer(devaddr, XFITReward.div(REWARD_FACTOR));
        pool.accXFITPerShare = pool.accXFITPerShare.add(
            XFITReward.mul(1e18).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
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

    // Safe XFIT transfer function, just in case if rounding error causes pool to not have enough XFITs.
    function safeXFITTransfer(address _to, uint256 _amount) internal {
        uint256 XFITBal = XFIT.balanceOf(address(this));
        if (_amount > XFITBal) {
            XFIT.transfer(_to, XFITBal);
        } else {
            XFIT.transfer(_to, _amount);
        }
    }

    // ADMIN METHODS

    // Update dev address by the admin.
    function dev(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function setPriceOracle(uint256 _pid, IXPriceOracle _xPoolOracle)
        public
        onlyOwner
    {
        PoolInfo storage pool = poolInfo[_pid];
        pool.xPoolOracle = _xPoolOracle;
    }

    function pauseDistribution() public onlyOwner {
        _pause();
    }

    function resumeDistribution() public onlyOwner {
        _unpause();
    }

    function setXFITRewardPerBlock(uint256 _newReward) public onlyOwner {
        massUpdatePools();
        XFITPerBlock = _newReward;
    }

    function withdrawAdminXFIT(uint256 amount) public onlyOwner {
        XFIT.transfer(msg.sender, amount);
    }

    function withdrawAdminFunding(uint256 _pid, uint256 _amount)
        public
        onlyOwner
    {
        PoolInfo memory pool = poolInfo[_pid];
        pool.inputToken.safeTransfer(msg.sender, _amount);
    }
}

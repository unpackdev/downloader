// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IBooster.sol";
import "./ILiqLocker.sol";
import "./IBaseRewardPool.sol";
import "./IRewardPool4626.sol";
import "./ILitDepositorHelper.sol";
import "./BalancerV2.sol";

// Oracle 0x9d43ccb1aD7E0081cC8A8F1fd54D16E54A637E30
interface IOracle {
    /**
     * @notice The multiplier applied to the TWAP value. Encodes the discount of the options token.
     * @return multiplier The multiplier in 4 decimals precision
     */
    function multiplier() external view returns (uint16 multiplier);
}

/**
 * @title   PooledOptionsExerciser
 * @author  LiquisFinance
 * @notice  Allows for claiming oLIT from RewardPools, exercise it and lock LIT received.
 * @dev     Implements a pooled exercise model where oLIT are queued and exercised in two steps.
 */
contract PooledOptionsExerciser {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public owner;
    address public immutable operator;
    address public immutable liqLit;
    address public immutable litDepositorHelper;
    address public immutable lockerRewards;
    address public immutable liqLocker;

    address public immutable lit = 0xfd0205066521550D7d7AB19DA8F72bb004b4C341;
    address public immutable olit = 0x627fee87d0D9D2c55098A06ac805Db8F98B158Aa;
    address public immutable olitOracle = 0x9d43ccb1aD7E0081cC8A8F1fd54D16E54A637E30;

    uint256 public constant basisOne = 10000;
    bytes32 internal constant balancerPoolId = 0x9232a548dd9e81bac65500b5e0d918f8ba93675c000200000000000000000423;

    // Option execution queue
    mapping(address => mapping(uint256 => uint256)) public queued; // owner => epoch => balance
    mapping(uint256 => uint256) public totalQueued; // epoch => total queued
    mapping(address => mapping(uint256 => uint256)) public withdrawn; // owner => epoch => balance
    mapping(uint256 => uint256) public totalWithdrawable; // epoch => total withdrawable

    uint256 public epoch; // execution queue epoch
    uint256 public fee; // fee paid to option executor expressed in bps (100=1%, 50=0.5%)

    event OwnerUpdated(address newOwner);
    event FeeUpdated(uint256 fee);
    event Queued(address owner, uint256 epoch, uint256 amount);
    event Unqueued(address owner, uint256 epoch, uint256 amount);
    event Exercised(uint256 epoch, uint256 amountIn, uint256 amountOut);
    event Withdrawn(address owner, uint256 epoch, uint256 amount);

    /**
     * @param _liqLit ERC20 token minted when locking LIT to veLIT in VoterProxy through crvDepositor.
     * @param _operator Booster main deposit contract; keeps track of pool info & user deposits; distributes rewards.
     * @param _litDepositorHelper Converts LIT -> balBPT and then wraps to liqLIT via the crvDepositor.
     * @param _lockerRewards BaseRewardPool where staking token is liqLIT.
     */
    constructor(
        address _liqLit,
        address _operator,
        address _litDepositorHelper,
        address _lockerRewards,
        address _liqLocker
    ) {
        liqLit = _liqLit;
        operator = _operator;
        litDepositorHelper = _litDepositorHelper;
        lockerRewards = _lockerRewards;
        liqLocker = _liqLocker;

        owner = msg.sender;

        epoch = 0;
        fee = 100; // 1% expressed in bps

        IERC20(lit).safeApprove(litDepositorHelper, type(uint256).max);

        emit OwnerUpdated(msg.sender);
        emit FeeUpdated(100);
    }

    /**
     * @notice Queue oLIT for execution
     * @param amount The amount of oLIT to be queued
     * @dev Adds queued oLIT to current epoch
     * @dev Reverts if insufficient balance
     */
    function queue(uint256 amount) external {
        IERC20(olit).safeTransferFrom(msg.sender, address(this), amount);

        queued[msg.sender][epoch] += amount;
        totalQueued[epoch] += amount;

        emit Queued(msg.sender, epoch, amount);
    }

    /**
     * @notice Claim oLIT rewards from liqLit staking and liqLocker
     * @param _pids Booster pools ids array to claim rewards from
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     */
    function claimAndQueue(
        uint256[] memory _pids,
        bool _locker,
        bool _liqLocker
    ) external returns (uint256 amount) {
        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            // claim all the rewards, only oLIT is sent here, the rest directly to sender
            amount += IBaseRewardPool(pool.crvRewards).getRewardFor(msg.sender, true);
        }

        if (_locker) {
            amount += IBaseRewardPool(lockerRewards).getRewardFor(msg.sender, true);
        }

        if (_liqLocker) {
            amount += ILiqLocker(liqLocker).getRewardFor(msg.sender);
        }

        // queue claimed oLIT rewards
        queued[msg.sender][epoch] += amount;
        totalQueued[epoch] += amount;

        emit Queued(msg.sender, epoch, amount);
    }

    /**
     * @notice Withdraw Bunni LpTokens and claim oLIT rewards from liqLit staking and liqLocker
     * @param _pids Booster pools ids array to claim rewards from
     * @param _amounts Amounts of stakingToken (Liquis LpToken) array to withdraw per pool id
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     * @dev owner needs to first approve this contract as spender on the rewards pool
     */
    function withdrawAndQueue(
        uint256[] memory _pids,
        uint256[] memory _amounts,
        bool _locker,
        bool _liqLocker
    ) external returns (uint256 amount) {
        require(_pids.length == _amounts.length, "array length missmatch");

        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            // sender will receive the Bunni LpTokens, already unwrapped
            IRewardPool4626(pool.crvRewards).withdraw(_amounts[i], msg.sender, msg.sender);
            // claim all the rewards, only oLIT is sent here, the rest directly to sender
            amount += IBaseRewardPool(pool.crvRewards).getRewardFor(msg.sender, true);
        }

        if (_locker) {
            amount += IBaseRewardPool(lockerRewards).getRewardFor(msg.sender, true);
        }

        if (_liqLocker) {
            amount += ILiqLocker(liqLocker).getRewardFor(msg.sender);
        }

        // queue claimed oLIT rewards
        queued[msg.sender][epoch] += amount;
        totalQueued[epoch] += amount;

        emit Queued(msg.sender, epoch, amount);
    }

    /**
     * @notice Unqueue oLIT from execution
     * @param amount The amount of oLIT to unqueue from execution
     * @dev Reverts if amount exceeds queued balance
     */
    function unqueue(uint256 amount) external {
        // queued balance
        uint256 _queued = queued[msg.sender][epoch];

        // revert if queued balance insufficient
        require(amount <= _queued, "insufficient balance");

        // unqueue
        queued[msg.sender][epoch] -= amount;
        totalQueued[epoch] -= amount;
        IERC20(olit).safeTransfer(msg.sender, amount);

        emit Unqueued(msg.sender, epoch, amount);
    }

    // compute oLIT amountIn and LIT amountOut for exercising the oLIT queued for execution in current epoch
    function _exerciseAmounts() internal view returns (uint256 amountIn, uint256 amountOut) {
        // oLIT amount available for exercise
        amountIn = totalQueued[epoch];

        if (amountIn == 0) return (0, 0);

        // oLIT execution price denominated in LIT and expressed in bps
        uint256 price = uint256(IOracle(olitOracle).multiplier()).mul(basisOne.add(fee)).div(basisOne);

        // amount of LIT available for claiming is exercised LIT minus execution price
        amountOut = amountIn.sub(amountIn.mul(price).div(basisOne));
    }

    /**
     * @notice Compute oLIT in and LIT out for option exercise
     * @return amountIn The amount of oLIT options exercised
     * @return amountOut The amount of LIT received
     */
    function exerciseAmounts() external view returns (uint256 amountIn, uint256 amountOut) {
        return _exerciseAmounts();
    }

    /**
     * @notice Exercise queued oLIT options
     * @dev Increments epoch
     */
    function exercise() external {
        // compute oLIT exercise amounts
        (uint256 amountIn, uint256 amountOut) = _exerciseAmounts();

        if (amountOut == 0) return;

        // Update withdrawable amount for epoch
        // note, can only exercise once for every epoch
        totalWithdrawable[epoch] += amountOut;
        epoch += 1;

        // Transfer oLIT to caller and LIT to exerciser contract
        IERC20(lit).safeTransferFrom(msg.sender, address(this), amountOut);
        IERC20(olit).safeTransfer(msg.sender, amountIn);

        emit Exercised(epoch - 1, amountIn, amountOut);
    }

    /**
     * @notice Withdraw exercised LIT
     * @param _epoch The epoch for which to withdraw LIT
     * @return withdrawn_ The LIT withdrawn
     * @dev Returns zero if nothing withdrawable
     */
    function withdraw(uint256 _epoch) external returns (uint256 withdrawn_) {
        // only withdraw past epochs
        require(_epoch < epoch, "epoch not withdrawable");

        // compute withdrawable LIT rewards for caller and _epoch
        withdrawn_ = _withdrawable(msg.sender, _epoch);

        // return if nothing claimable
        if (withdrawn_ == 0) return 0;

        // update withdrawn amount for user and epoch
        withdrawn[msg.sender][_epoch] += withdrawn_;

        // transfer withdrawable LIT
        IERC20(lit).safeTransfer(msg.sender, withdrawn_);

        emit Withdrawn(msg.sender, _epoch, withdrawn_);
    }

    /**
     * @notice Withdraw exercised LIT and lock as liqLIT
     * @param _epoch Epoch for which to withdraw and lock LIT
     * @param _stake Stake liqLit into the liqLit staking rewards pool
     * @param _minOut Units of BPT to expect as output
     * @return withdrawn_ The amount of LIT rewards withdrawn and locked
     */
    function withdrawAndLock(
        uint256 _epoch,
        bool _stake,
        uint256 _minOut
    ) external returns (uint256 withdrawn_) {
        // only withdraw past epochs
        require(_epoch < epoch, "epoch not withdrawable");

        // compute withdrawable LIT rewards for caller and _epoch
        withdrawn_ = _withdrawable(msg.sender, _epoch);

        // return if nothing claimable
        if (withdrawn_ == 0) return 0;

        // update withdrawn amount for user and epoch
        withdrawn[msg.sender][_epoch] += withdrawn_;

        // convert lit to liqLit, send it to sender or stake it in liqLit staking
        // note, convert _maxSlippage to _outputBps param used in BalInvestor
        _convertLitToLiqLit(withdrawn_, _minOut, _stake);

        emit Withdrawn(msg.sender, _epoch, withdrawn_);
    }

    function _convertLitToLiqLit(
        uint256 amount,
        uint256 _minOut,
        bool _stake
    ) internal {
        _stake == true
            ? ILitDepositorHelper(litDepositorHelper).depositFor(msg.sender, amount, _minOut, true, lockerRewards, lit)
            : ILitDepositorHelper(litDepositorHelper).depositFor(msg.sender, amount, _minOut, true, address(0), lit);
    }

    /**
     * @notice User claims their olit from pool, converts into liqLit and sends it back to the user
     * @param account The account for which to query withdrawable LIT
     * @param _epoch Epoch for which to query withdrawable LIT
     * @return withdrawable_ The amount of withdrawable LIT rewards
     */
    function withdrawable(address account, uint256 _epoch) external view returns (uint256 withdrawable_) {
        withdrawable_ = _withdrawable(account, _epoch);
    }

    // internal function to view withdrawable LIT rewards by account and epoch
    function _withdrawable(address account, uint256 _epoch) internal view returns (uint256 withdrawable_) {
        // note, totalQueued > 0 for all past epochs
        uint256 share = queued[account][_epoch].mul(1e18).div(totalQueued[_epoch]);
        withdrawable_ = share.mul(totalWithdrawable[_epoch]).div(1e18).sub(withdrawn[account][_epoch]);
    }

    /**
     * @notice Owner is responsible for setting initial config and updating operational params
     */
    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    /**
     * @notice Updates the fee parameter within a restricted range
     * @param _fee The fee in bps for compensating the option exerciser
     */
    function setFee(uint256 _fee) external {
        require(msg.sender == owner, "!auth");
        require(_fee <= basisOne, "unsupported value");
        fee = _fee;
        emit FeeUpdated(_fee);
    }
}

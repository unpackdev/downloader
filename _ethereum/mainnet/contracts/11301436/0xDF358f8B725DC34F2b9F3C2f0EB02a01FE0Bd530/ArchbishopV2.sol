pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath96.sol";
import "./SafeMath32.sol";

// Archbishop will crown the King and he is a fair guy...
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once $KING is sufficiently
// distributed and the community can show to govern itself.
contract ArchbishopV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 wAmount; // Weighted amount = lptAmount + (stAmount * pool.sTokenWeight)
        uint256 stAmount; // How many S tokens the user has provided
        uint256 lptAmount; // How many LP tokens the user has provided
        uint96 pendingKing; // $KING tokens pending to be given to user
        uint96 rewardDebt; // Reward debt (see explanation below)
        uint32 lastWithdrawBlock; // User last withdraw time

        // We do some fancy math here. Basically, any point in time, the amount of $KINGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.wAmount * pool.accKingPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKingPerShare` (and `lastRewardBlock`) gets updated
        //   2. User receives the pending reward sent to his/her address
        //   3. User's `wAmount` gets updated
        //   4. User's `rewardDebt` gets updated
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract
        uint32 allocPoint; // Allocation points assigned to this pool (for $KINGs distribution)
        uint32 lastRewardBlock; // Last block number that $KINGs distribution occurs
        uint32 sTokenWeight; // "Weight" of LP token in SToken, times 1e8
        IERC20 sToken; // Address of S token contract
        bool kingLock; // if true, withdraw interval, or withdraw fees otherwise, applied on $KING withdrawals
        uint256 accKingPerShare; // Accumulated $KINGs per share, times 1e12 (see above)
    }

    // The $KING token contract
    address public king;

    // The kingServant contract (that receives LP token fees)
    address public kingServant;
    // fees on LP token withdrawals, in percents
    uint8 public lpFeePct = 0;

    // The courtJester address (that receives $KING fees)
    address public courtJester;
    // fees on $KING withdrawals, in percents (charged if `pool.kingLock` is `false`)
    uint8 public kingFeePct = 0;
    // Withdraw interval, in blocks, takes effect if pool.kingLock is `true`
    uint32 public withdrawInterval;

    // $KING token amount distributed every block of LP token farming
    uint96 public kingPerLptFarmingBlock;
    // $KING token amount distributed every block of S token farming
    uint96 public kingPerStFarmingBlock;
    // The sum of allocation points in all pools
    uint32 public totalAllocPoint;

    // The block when yield and trade farming starts
    uint32 public startBlock;
    // Block when LP token farming ends
    uint32 public lptFarmingEndBlock;
    // Block when S token farming ends
    uint32 public stFarmingEndBlock;

    // Info of each pool
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount,
        uint256 stAmount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );

    constructor(
        address _king,
        address _kingServant,
        address _courtJester,
        uint256 _startBlock,
        uint256 _withdrawInterval
    ) public {
        king = _nonZeroAddr(_king);
        kingServant = _nonZeroAddr(_kingServant);
        courtJester = _nonZeroAddr(_courtJester);
        startBlock = SafeMath32.fromUint(_startBlock);
        withdrawInterval = SafeMath32.fromUint(_withdrawInterval);
    }

    function setFarmingParams(
        uint256 _kingPerLptFarmingBlock,
        uint256 _kingPerStFarmingBlock,
        uint256 _lptFarmingEndBlock,
        uint256 _stFarmingEndBlock
    ) external onlyOwner {
        _setFarmingParams(
            SafeMath96.fromUint(_kingPerLptFarmingBlock),
            SafeMath96.fromUint(_kingPerStFarmingBlock),
            SafeMath32.fromUint(_lptFarmingEndBlock),
            SafeMath32.fromUint(_stFarmingEndBlock)
        );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new LP pool. Owner only may call.
    function add(
        uint256 allocPoint,
        uint256 sTokenWeight,
        IERC20 lpToken,
        IERC20 sToken,
        bool withUpdate
    ) public onlyOwner {
        require(_isMissingPool(lpToken, sToken), "ArchV2::add:POOL_EXISTS");
        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        if (withUpdate) massUpdatePools();

        uint32 curBlock = curBlock();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                sToken: sToken,
                allocPoint: SafeMath32.fromUint(_allocPoint),
                sTokenWeight: SafeMath32.fromUint(sTokenWeight),
                lastRewardBlock: curBlock > startBlock ? curBlock : startBlock,
                accKingPerShare: 0,
                kingLock: true
            })
        );
    }

    // Update the given pool's $KING allocation point. Owner only may call.
    function setAllocation(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[pid].allocPoint = _allocPoint;
    }

    function setSTokenWeight(
        uint256 pid,
        uint256 sTokenWeight,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].sTokenWeight = SafeMath32.fromUint(sTokenWeight);
    }

    function setKingLock(
        uint256 pid,
        bool _kingLock,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].kingLock = _kingLock;
    }

    // Return reward multipliers for LP and S tokens over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint256 lpt, uint256 st)
    {
        (uint32 _lpt, uint32 _st) = _getMultiplier(
            SafeMath32.fromUint(from),
            SafeMath32.fromUint(to)
        );
        lpt = uint256(_lpt);
        st = uint256(_st);
    }

    function getKingPerBlock(uint256 blockNum) public view returns (uint256) {
        return
            (blockNum > stFarmingEndBlock ? 0 : kingPerStFarmingBlock).add(
                blockNum > lptFarmingEndBlock ? 0 : kingPerLptFarmingBlock
            );
    }

    // View function to see pending $KINGs on frontend.
    function pendingKing(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 kingPerShare = pool.accKingPerShare;

        uint32 curBlock = curBlock();
        uint256 lptSupply = pool.lpToken.balanceOf(address(this));

        if (curBlock > pool.lastRewardBlock && lptSupply != 0) {
            (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
                pool.lastRewardBlock,
                curBlock
            );
            uint96 kingReward = _kingReward(
                lptFactor,
                stFactor,
                pool.allocPoint
            );
            if (kingReward != 0) {
                uint256 stSupply = pool.sToken.balanceOf(address(this));
                uint256 wSupply = _weighted(
                    lptSupply,
                    stSupply,
                    pool.sTokenWeight
                );
                kingPerShare = _accShare(kingPerShare, kingReward, wSupply);
            }
        }

        return
            _accPending(
                user.pendingKing,
                user.wAmount,
                user.rewardDebt,
                kingPerShare
            );
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool
    function updatePool(uint256 pid) public {
        _validatePid(pid);
        _updatePool(pid);
    }

    // Deposit lptAmount of LP token and stAmount of S token to mine $KING,
    // (it sends to msg.sender $KINGs pending by then)
    function deposit(
        uint256 pid,
        uint256 lptAmount,
        uint256 stAmount
    ) public nonReentrant {
        require(lptAmount != 0, "deposit: zero LP token amount");
        _validatePid(pid);

        _updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 oldStAmount = user.stAmount;
        uint96 pendingKingAmount = _accPending(
            user.pendingKing,
            user.wAmount,
            user.rewardDebt,
            pool.accKingPerShare
        );
        user.lptAmount = user.lptAmount.add(lptAmount);
        user.stAmount = user.stAmount.add(stAmount);
        user.wAmount = _accWeighted(
            user.wAmount,
            lptAmount,
            stAmount,
            pool.sTokenWeight
        );

        uint32 curBlock = curBlock();
        if (
            _sendKingToken(
                msg.sender,
                pendingKingAmount,
                pool.kingLock,
                curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = curBlock;
            user.pendingKing = 0;
            pool.sToken.safeTransfer(address(1), oldStAmount);
        } else {
            user.pendingKing = pendingKingAmount;
        }
        user.rewardDebt = _pending(user.wAmount, 0, pool.accKingPerShare);

        pool.lpToken.safeTransferFrom(msg.sender, address(this), lptAmount);
        if (stAmount != 0)
            pool.sToken.safeTransferFrom(msg.sender, address(this), stAmount);

        emit Deposit(msg.sender, pid, lptAmount, stAmount);
    }

    // Withdraw lptAmount of LP token and all pending $KING tokens
    // (it burns all S tokens)
    function withdraw(uint256 pid, uint256 lptAmount) public nonReentrant {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 preLptAmount = user.wAmount;
        require(preLptAmount >= lptAmount, "withdraw: LP amount not enough");

        user.lptAmount = preLptAmount.sub(lptAmount);
        uint256 stAmount = user.stAmount;

        _updatePool(pid);
        uint96 pendingKingAmount = _accPending(
            user.pendingKing,
            user.wAmount,
            user.rewardDebt,
            pool.accKingPerShare
        );
        user.wAmount = user.lptAmount;
        user.rewardDebt = _pending(user.wAmount, 0, pool.accKingPerShare);
        user.stAmount = 0;
        uint32 curBlock = curBlock();

        if (
            _sendKingToken(
                msg.sender,
                pendingKingAmount,
                pool.kingLock,
                curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = curBlock;
            user.pendingKing = 0;
        } else {
            user.pendingKing = pendingKingAmount;
        }

        uint256 sentLptAmount = lptAmount == 0
            ? 0
            : _sendLptAndBurnSt(msg.sender, pool, lptAmount, stAmount);
        emit Withdraw(msg.sender, pid, sentLptAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // (it clears all pending $KINGs and burns all S tokens)
    function emergencyWithdraw(uint256 pid) public {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 lptAmount = user.lptAmount;
        user.lptAmount = 0; // serves as "non-reentrant"
        require(lptAmount > 0, "withdraw: zero LP token amount");

        uint32 curBlock = curBlock();
        uint256 stAmount = user.stAmount;
        user.wAmount = 0;
        user.stAmount = 0;
        user.rewardDebt = 0;
        user.pendingKing = 0;
        user.lastWithdrawBlock = curBlock;

        uint256 sentLptAmount = _sendLptAndBurnSt(
            msg.sender,
            pool,
            lptAmount,
            stAmount
        );
        emit EmergencyWithdraw(msg.sender, pid, sentLptAmount);
    }

    function setKingServant(address _kingServant) public onlyOwner {
        kingServant = _nonZeroAddr(_kingServant);
    }

    function setCourtJester(address _courtJester) public onlyOwner {
        courtJester = _nonZeroAddr(_courtJester);
    }

    function setKingFeePct(uint256 newPercent) public onlyOwner {
        kingFeePct = _validPercent(newPercent);
    }

    function setLpFeePct(uint256 newPercent) public onlyOwner {
        lpFeePct = _validPercent(newPercent);
    }

    function setWithdrawInterval(uint256 _blockNum) public onlyOwner {
        withdrawInterval = SafeMath32.fromUint(_blockNum);
    }

    function _updatePool(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        uint32 lastUpdateBlock = pool.lastRewardBlock;

        uint32 curBlock = curBlock();
        if (curBlock <= lastUpdateBlock) return;
        pool.lastRewardBlock = curBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            lastUpdateBlock,
            curBlock
        );
        if (lptFactor == 0 && stFactor == 0) return;

        uint256 lptSupply = pool.lpToken.balanceOf(address(this));
        if (lptSupply == 0) return;

        uint256 stSupply = pool.sToken.balanceOf(address(this));
        uint256 wSupply = _weighted(lptSupply, stSupply, pool.sTokenWeight);

        uint96 kingReward = _kingReward(lptFactor, stFactor, pool.allocPoint);
        pool.accKingPerShare = _accShare(
            pool.accKingPerShare,
            kingReward,
            wSupply
        );
    }

    function _sendKingToken(
        address user,
        uint96 amount,
        bool kingLock,
        uint32 blocksSinceLastWithdraw
    ) internal returns (bool isSent) {
        isSent = true;
        if (amount == 0) return isSent;

        uint256 feeAmount = 0;
        uint256 userAmount = 0;

        if (!kingLock) {
            userAmount = amount;
            if (kingFeePct != 0) {
                feeAmount = uint256(amount).mul(kingFeePct).div(100);
                userAmount = userAmount.sub(feeAmount);

                IERC20(king).safeTransfer(courtJester, feeAmount);
            }
        } else if (blocksSinceLastWithdraw > withdrawInterval) {
            userAmount = amount;
        } else {
            return isSent = false;
        }

        uint256 balance = IERC20(king).balanceOf(address(this));
        IERC20(king).safeTransfer(
            user,
            // if balance lacks some tiny $KING amount due to imprecise rounding
            userAmount > balance ? balance : userAmount
        );
    }

    function _sendLptAndBurnSt(
        address user,
        PoolInfo storage pool,
        uint256 lptAmount,
        uint256 stAmount
    ) internal returns (uint256) {
        uint256 userLptAmount = lptAmount;

        if (curBlock() < stFarmingEndBlock && lpFeePct != 0) {
            uint256 lptFee = lptAmount.mul(lpFeePct).div(100);
            userLptAmount = userLptAmount.sub(lptFee);

            pool.lpToken.safeTransfer(kingServant, lptFee);
        }

        if (userLptAmount != 0) pool.lpToken.safeTransfer(user, userLptAmount);
        if (stAmount != 0) pool.sToken.safeTransfer(address(1), stAmount);

        return userLptAmount;
    }

    function _safeKingTransfer(address _to, uint256 _amount) internal {
        uint256 kingBal = IERC20(king).balanceOf(address(this));
        // if pool lacks some tiny $KING amount due to imprecise rounding
        IERC20(king).safeTransfer(_to, _amount > kingBal ? kingBal : _amount);
    }

    function _setFarmingParams(
        uint96 _kingPerLptFarmingBlock,
        uint96 _kingPerStFarmingBlock,
        uint32 _lptFarmingEndBlock,
        uint32 _stFarmingEndBlock
    ) internal {
        require(
            _lptFarmingEndBlock >= lptFarmingEndBlock,
            "ArchV2::lptFarmingEndBlock"
        );
        require(
            _stFarmingEndBlock >= stFarmingEndBlock,
            "ArchV2::stFarmingEndBlock"
        );

        if (lptFarmingEndBlock != _lptFarmingEndBlock)
            lptFarmingEndBlock = _lptFarmingEndBlock;
        if (stFarmingEndBlock != _stFarmingEndBlock)
            stFarmingEndBlock = _stFarmingEndBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            curBlock(),
            2**32 - 1
        );
        uint256 minBalance = (
            uint256(_kingPerLptFarmingBlock).mul(uint256(stFactor))
        )
            .add(uint256(_kingPerStFarmingBlock).mul(uint256(lptFactor)));
        require(
            IERC20(king).balanceOf(address(this)) >= minBalance,
            "ArchV2::LOW_$KING_BALANCE"
        );

        kingPerLptFarmingBlock = _kingPerLptFarmingBlock;
        kingPerStFarmingBlock = _kingPerStFarmingBlock;
    }

    // Revert if the LP token has been already added.
    function _isMissingPool(IERC20 lpToken, IERC20 sToken)
        internal
        view
        returns (bool)
    {
        _revertZeroAddress(address(lpToken));
        _revertZeroAddress(address(lpToken));
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (
                poolInfo[i].lpToken == lpToken || poolInfo[i].sToken == sToken
            ) {
                return false;
            }
        }
        return true;
    }

    function _getMultiplier(uint32 _from, uint32 _to)
        internal
        view
        returns (uint32 lpt, uint32 st)
    {
        uint32 start = _from > startBlock ? _from : startBlock;

        // LP token farming multiplier
        uint32 end = _to > lptFarmingEndBlock ? lptFarmingEndBlock : _to;
        lpt = _from < lptFarmingEndBlock ? end.sub(start) : 0;

        // S token farming multiplier
        end = _to > stFarmingEndBlock ? stFarmingEndBlock : _to;
        st = _from < stFarmingEndBlock ? end.sub(start) : 0;
    }

    function _accPending(
        uint96 prevPending,
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? prevPending
                : prevPending.add(_pending(amount, rewardDebt, accPerShare));
    }

    function _pending(
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? 0
                : SafeMath96.fromUint(
                    amount.mul(accPerShare).div(1e12).sub(uint256(rewardDebt)),
                    "ArchV2::pending:overflow"
                );
    }

    function _kingReward(
        uint32 lptFactor,
        uint32 stFactor,
        uint32 allocPoint
    ) internal view returns (uint96) {
        uint32 _totalAllocPoint = totalAllocPoint;
        uint96 lptReward = _reward(
            lptFactor,
            kingPerLptFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        if (stFactor == 0) return lptReward;

        uint96 stReward = _reward(
            stFactor,
            kingPerStFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        return lptReward.add(stReward);
    }

    function _reward(
        uint32 factor,
        uint96 rewardPerBlock,
        uint32 allocPoint,
        uint32 _totalAllocPoint
    ) internal pure returns (uint96) {
        return
            SafeMath96.fromUint(
                uint256(factor)
                    .mul(uint256(rewardPerBlock))
                    .mul(uint256(allocPoint))
                    .div(uint256(_totalAllocPoint))
            );
    }

    function _accShare(
        uint256 prevShare,
        uint96 reward,
        uint256 supply
    ) internal pure returns (uint256) {
        return prevShare.add(uint256(reward).mul(1e12).div(supply));
    }

    function _accWeighted(
        uint256 prevAmount,
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        return prevAmount.add(_weighted(lptAmount, stAmount, sTokenWeight));
    }

    function _weighted(
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        if (stAmount == 0 || sTokenWeight == 0) {
            return lptAmount;
        }
        return lptAmount.add(stAmount.mul(sTokenWeight).div(1e8));
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function curBlock() private view returns (uint32) {
        return SafeMath32.fromUint(block.number);
    }

    function _validPercent(uint256 percent) private pure returns (uint8) {
        require(percent <= 100, "ArchV2::INVALID_PERCENT");
        return uint8(percent);
    }

    function _revertZeroAddress(address _address) internal pure {
        require(_address != address(0), "ArchV2::ZERO_ADDRESS");
    }

    function _validatePid(uint256 pid) private view returns (uint256) {
        require(pid < poolInfo.length, "ArchV2::INVALID_POOL_ID");
        return pid;
    }
}

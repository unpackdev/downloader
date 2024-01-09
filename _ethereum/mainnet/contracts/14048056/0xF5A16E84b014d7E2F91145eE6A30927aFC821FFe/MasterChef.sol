// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./IAMM.sol";
import "./ILPToken.sol";
import "./IFutureVault.sol";
import "./IRewarder.sol";

// MasterChef is the master of APW. He can make APW and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once APW is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is OwnableUpgradeable, ERC1155HolderUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ILPToken;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 periodId;
        //
        // We do some fancy math here. Basically, any point in time, the amount of APWs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAPWPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. User receives the pending reward sent to his/her address for this pool.
        //   2. User's `amount` gets updated.
        //   3. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. APWs to distribute per block.
        uint256 accAPWPerShare; // Accumulated APWs per share, times 1e12. See below.
        uint256 lastRewardBlock; // Last block number that APWs distribution occurs.
        uint256 ammId;
        uint256 pairId;
    }

    EnumerableSetUpgradeable.UintSet internal activePools; // list of tokenId to update

    mapping(uint256 => mapping(uint256 => uint256)) internal poolToPeriodId; // ammid => paird => period
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(uint256 => mapping(address => UserInfo))) public userInfo; // ammid => pairId => user address => user info

    mapping(uint256 => address) public lpIDToFutureAddress;

    mapping(uint256 => uint256) public nextUpgradeAllocPoint;

    mapping(uint256 => IRewarder) public rewarders;
    uint256 private constant TOKEN_PRECISION = 1e12;
    // The APW TOKEN!
    IERC20Upgradeable public apw;
    // The APWine LP token
    ILPToken public lpToken;
    // APW tokens created per block.
    uint256 public apwPerBlock;
    // Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    // ERC-165 identifier for the main token standard.
    bytes4 public constant ERC1155_ERC165 = 0xd9b67a26;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userLpTokensIds;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when APW mining starts.
    uint256 public startBlock;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "MasterChef: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    modifier validPool(uint256 _lpTokenId) {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        require(poolToPeriodId[ammId][pairId] != 0, "MasterChef: invalid pool id");
        _;
    }

    event Deposit(address indexed user, uint256 indexed lpTokenId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed lpTokenId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed lpTokenId, uint256 amount);
    event NextAllocPointSet(uint256 indexed previousLpTokenId, uint256 nextAllocPoint);
    event LpIdToFutureSet(uint256 _lpTokenId, address futureAddress);
    event Harvest(address indexed user, uint256 indexed lpTokenId, uint256 amount);

    function initialize(
        address _apw,
        address _lpToken,
        uint256 _apwPerBlock,
        uint256 _startBlock
    ) external initializer {
        require(_apw != address(0), "MasterChef: Invalid APW address provided");
        require(_lpToken != address(0), "MasterChef: Invalid LPToken address provided");
        require(_apwPerBlock > 0, "MasterChef: !apwPerBlock-0");

        apw = IERC20Upgradeable(_apw);
        lpToken = ILPToken(_lpToken);
        apwPerBlock = _apwPerBlock;
        startBlock = _startBlock;
        totalAllocPoint = 0;
        _status = _NOT_ENTERED;
        __Ownable_init();
        _registerInterface(ERC1155_ERC165);
    }

    // Add a new LP token to the pool. Can only be called by the owner.
    // Cannot add same LP token twice.
    function add(
        uint256 _allocPoint,
        uint256 _lpTokenId,
        IRewarder _rewarder,
        bool _withUpdate
    ) external onlyOwner {
        // TODO: Slipping zero check for allocPoint, that scenario is considered and will not cause a problem
        _add(_allocPoint, _lpTokenId, _rewarder, _withUpdate);
    }

    function _add(
        uint256 _allocPoint,
        uint256 _lpTokenId,
        IRewarder _rewarder,
        bool _withUpdate
    ) internal {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        uint64 periodId = lpToken.getPeriodIndex(_lpTokenId);
        address ammAddress = lpToken.amms(ammId);
        require(ammAddress != address(0), "MasterChef: LPTokenId Invalid");
        require(poolToPeriodId[ammId][pairId] != periodId, "MasterChef: LP Token already added");
        address futureAddress = IAMM(ammAddress).getFutureAddress();
        uint256 lastPeriodId = IFutureVault(futureAddress).getCurrentPeriodIndex();
        require(periodId == lastPeriodId, "MasterChef: Invalid period ID for LP Token");
        lpIDToFutureAddress[_lpTokenId] = futureAddress;
        rewarders[_lpTokenId] = _rewarder;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo[_lpTokenId] = PoolInfo({
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accAPWPerShare: 0,
            ammId: ammId,
            pairId: pairId
        });
        activePools.add(_lpTokenId);
        poolToPeriodId[ammId][pairId] = periodId;
    }

    // Update the given pool's APW allocation point. Can only be called by the owner.
    /// @param _lpTokenId The lpTokenId of the pool
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        uint256 _lpTokenId,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite,
        bool _withUpdate
    ) external onlyOwner {
        // TODO: Slipping zero check for allocPoint, that scenario is considered and will not cause a problem
        _set(_lpTokenId, _allocPoint, _rewarder, overwrite, _withUpdate);
    }

    function _set(
        uint256 _lpTokenId,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite,
        bool _withUpdate
    ) internal validPool(_lpTokenId) {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_lpTokenId].allocPoint).add(_allocPoint);
        poolInfo[_lpTokenId].allocPoint = _allocPoint;
        if (overwrite) {
            rewarders[_lpTokenId] = _rewarder;
        }
    }

    // View function to see pending APWs on frontend.
    function pendingAPW(uint256 _lpTokenId, address _user) external view validPool(_lpTokenId) returns (uint256) {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        UserInfo storage user = userInfo[ammId][pairId][_user];
        PoolInfo storage pool = poolInfo[_lpTokenId];
        uint256 accAPWPerShare = pool.accAPWPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(this), _lpTokenId);
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 apwReward =
                (block.number.sub(pool.lastRewardBlock)).mul(apwPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            accAPWPerShare = accAPWPerShare.add(apwReward.mul(TOKEN_PRECISION).div(lpSupply));
        }

        return user.amount.mul(accAPWPerShare).div(TOKEN_PRECISION).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = activePools.length();
        for (uint256 i = 0; i < length; ++i) {
            updatePool(activePools.at(i));
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _lpTokenId) public validPool(_lpTokenId) {
        PoolInfo storage pool = poolInfo[_lpTokenId];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this), _lpTokenId);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 apwReward =
            totalAllocPoint == 0
                ? 0
                : (block.number.sub(pool.lastRewardBlock)).mul(apwPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accAPWPerShare = pool.accAPWPerShare.add(apwReward.mul(TOKEN_PRECISION).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update pool rewards, setting previous at 0 and creating a new one with the same parameters
    function _upgradePoolRewardsIfNeeded(uint64 _ammId, uint256 _pairId) internal returns (bool) {
        address ammAddress = lpToken.amms(_ammId);
        uint256 lastPeriodId = IFutureVault(IAMM(ammAddress).getFutureAddress()).getCurrentPeriodIndex();
        uint256 previousPeriodId = poolToPeriodId[_ammId][_pairId];
        uint previousLpTokenId = IAMM(ammAddress).getLPTokenId(_ammId, previousPeriodId, _pairId);
        if (lastPeriodId > previousPeriodId) {
            _set(previousLpTokenId, 0, IRewarder(0x0), false, false); // remove rewards for old period
            uint256 newLpTokenId = IAMM(ammAddress).getLPTokenId(_ammId, lastPeriodId, _pairId);
            activePools.remove(previousLpTokenId); // remove old pool from active ones
            IRewarder rewarder = rewarders[previousLpTokenId];
            _add(nextUpgradeAllocPoint[previousLpTokenId], newLpTokenId, rewarder, false); // add rewards for the new period
            if (address(rewarder) != address(0x0)) rewarder.renewPool(previousLpTokenId, newLpTokenId);
            return true;
        } else {
            return false;
        }
    }

    // Deposit LP tokens to MasterChef for APW allocation.
    function deposit(uint256 _lpTokenId, uint256 _amount) external validPool(_lpTokenId) nonReentrant {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        _upgradePoolRewardsIfNeeded(ammId, pairId);

        uint256 periodOfToken = lpToken.getPeriodIndex(_lpTokenId);
        uint256 lastPeriodId = IFutureVault(lpIDToFutureAddress[_lpTokenId]).getCurrentPeriodIndex();
        require(periodOfToken == lastPeriodId, "Masterchef: Invalid period Id for Token");

        updatePool(_lpTokenId);

        PoolInfo storage pool = poolInfo[_lpTokenId];
        UserInfo storage user = userInfo[ammId][pairId][msg.sender];

        if (user.amount > 0) {
            uint256 lastUserLpTokenId = IAMM(lpToken.amms(ammId)).getLPTokenId(ammId, user.periodId, pairId);
            uint256 accAPWPerShare =
                (user.periodId != 0 && user.periodId < periodOfToken)
                    ? poolInfo[lastUserLpTokenId].accAPWPerShare
                    : pool.accAPWPerShare;
            uint256 pending = user.amount.mul(accAPWPerShare).div(TOKEN_PRECISION).sub(user.rewardDebt);

            if (pending > 0) require(safeAPWTransfer(msg.sender, pending), "Masterchef: SafeTransfer APW failed");
        }
        if (user.periodId != periodOfToken) {
            userLpTokensIds[msg.sender].remove(IAMM(lpToken.amms(ammId)).getLPTokenId(ammId, pairId, user.periodId));
            user.amount = 0;
            user.rewardDebt = 0;
            user.periodId = periodOfToken;
        }

        if (_amount > 0) lpToken.safeTransferFrom(address(msg.sender), address(this), _lpTokenId, _amount, "");
        user.amount = user.amount.add(_amount);
        userLpTokensIds[msg.sender].add(_lpTokenId);
        user.rewardDebt = user.amount.mul(pool.accAPWPerShare).div(TOKEN_PRECISION);

        IRewarder _rewarder = rewarders[_lpTokenId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onAPWReward(_lpTokenId, msg.sender, msg.sender, user.amount);
        }

        emit Deposit(msg.sender, _lpTokenId, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _lpTokenId, uint256 _amount) external validPool(_lpTokenId) nonReentrant {
        PoolInfo storage pool = poolInfo[_lpTokenId];
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        UserInfo storage user = userInfo[ammId][pairId][msg.sender];
        if (totalAllocPoint != 0) updatePool(_lpTokenId);
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending = user.amount.mul(pool.accAPWPerShare).div(TOKEN_PRECISION).sub(user.rewardDebt);
        if (pending > 0) require(safeAPWTransfer(msg.sender, pending), "Masterchef: SafeTransfer APW failed");
        user.amount = user.amount.sub(_amount);
        if (user.amount == 0) userLpTokensIds[msg.sender].remove(_lpTokenId);
        user.rewardDebt = user.amount.mul(pool.accAPWPerShare).div(TOKEN_PRECISION);
        IRewarder _rewarder = rewarders[_lpTokenId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onAPWReward(_lpTokenId, msg.sender, msg.sender, user.amount);
        }
        if (_amount > 0) lpToken.safeTransferFrom(address(this), address(msg.sender), _lpTokenId, _amount, "");
        emit Withdraw(msg.sender, _lpTokenId, _amount);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param _lpTokenId The index of the pool. See `poolInfo`.
    /// @param to Receiver of SUSHI rewards.
    function harvest(uint256 _lpTokenId, address to) public nonReentrant {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        UserInfo storage user = userInfo[ammId][pairId][msg.sender];

        require(user.amount != 0, "Masterchef: invalid lp address");

        uint256 accumulatedAPW = uint256(user.amount.mul(poolInfo[_lpTokenId].accAPWPerShare) / TOKEN_PRECISION);
        uint256 _pendingAPW = accumulatedAPW.sub(user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedAPW;

        // Interactions
        if (_pendingAPW != 0) {
            safeAPWTransfer(to, _pendingAPW);
        }

        IRewarder _rewarder = rewarders[_lpTokenId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onAPWReward(_lpTokenId, msg.sender, to, user.amount);
        }

        emit Harvest(msg.sender, _lpTokenId, _pendingAPW);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _lpTokenId) external validPool(_lpTokenId) nonReentrant {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        UserInfo storage user = userInfo[ammId][pairId][msg.sender];
        uint256 userAmount = user.amount;
        if (userAmount > 0)  {
            user.amount = 0;
            user.rewardDebt = 0;
            lpToken.safeTransferFrom(address(this), address(msg.sender), _lpTokenId, userAmount, "");
        }
        IRewarder _rewarder = rewarders[_lpTokenId];
        if (address(_rewarder) != address(0)) {
            _rewarder.onAPWReward(_lpTokenId, msg.sender, msg.sender, 0);
        }
        userLpTokensIds[msg.sender].remove(_lpTokenId);
        emit EmergencyWithdraw(msg.sender, _lpTokenId, userAmount);
    }

    // Safe apw transfer function, just in case if rounding error causes pool to not have enough APWs.
    function safeAPWTransfer(address _to, uint256 _amount) internal returns (bool success) {
        uint256 apwBal = apw.balanceOf(address(this));
        uint256 transferAmount = (_amount > apwBal) ? apwBal : _amount;
        success = apw.transfer(_to, transferAmount);
    }

    // **** Additional functions separate from the original masterchef contract ****
    function setAPWPerBlock(uint256 _apwPerBlock) external onlyOwner {
        massUpdatePools();
        require(_apwPerBlock > 0, "!apwPerBlock-0");
        apwPerBlock = _apwPerBlock;
    }

    // Set the lpIDToFutureAddress
    function setlpIDToFuture(uint256 _lpTokenId, address futureAddress) external validPool(_lpTokenId) onlyOwner {
        lpIDToFutureAddress[_lpTokenId] = futureAddress;
        emit LpIdToFutureSet(_lpTokenId, futureAddress);
    }

    // Withdraw APWs on the contract
    function withdrawAPW(address _recipient, uint256 _amount) external onlyOwner {
        if (_amount > 0) apw.transfer(_recipient, _amount);
    }

    // Set the next allocPoint on period upgrade
    function setNextUpgradeAllocPoint(uint256 _lpTokenId, uint256 _nextAllocPoint) external validPool(_lpTokenId) onlyOwner {
        uint64 ammId = lpToken.getAMMId(_lpTokenId);
        uint256 pairId = lpToken.getPairId(_lpTokenId);
        uint256 periodId = lpToken.getPeriodIndex(_lpTokenId);
        require(periodId == poolToPeriodId[ammId][pairId], "Masterchef: pool already upgraded");
        nextUpgradeAllocPoint[_lpTokenId] = _nextAllocPoint;
        emit NextAllocPointSet(_lpTokenId, _nextAllocPoint);
    }

    function isRegisteredPoolId(uint256 _poolId) external view returns (bool) {
        return activePools.contains(_poolId);
    }

    function poolIdsLength() external view returns (uint256) {
        return activePools.length();
    }

    function poolIdAt(uint256 _id) external view returns (uint256) {
        return activePools.at(_id);
    }

    function getUserLpTokenIdList(address _user) external view returns (uint256[] memory) {
        uint256 length = userLpTokensIds[_user].length();
        uint256[] memory _userLpTokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _userLpTokenIds[i] = userLpTokensIds[_user].at(i);
        }
        return _userLpTokenIds;
    }
}

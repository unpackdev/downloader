// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./DSMath.sol";
import "./IVeWom.sol";
import "./IVoter.sol";
import "./IBribeRewarderFactory.sol";
import "./IBoostedMasterWombat.sol";
import "./IBoostedMultiRewarder.sol";
import "./IMultiRewarder.sol";

/// @title BoostedMasterWombat
/// @notice MasterWombat is a boss. He is not afraid of any snakes. In fact, he drinks their venoms. So, veWom holders boost
/// their (boosted) emissions. This contract rewards users in function of their amount of lp staked (base pool) factor (boosted pool)
/// Factor and sumOfFactors are updated by contract VeWom.sol after any veWom minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Wombat is sufficiently
/// distributed and the community can show to govern itself.
/// @dev Updates:
/// - Compatible with gauge voting
/// - Add support for BoostedMultiRewarder
contract BoostedMasterWombat is
    IBoostedMasterWombat,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // Use `Native` for generic purpose
    string internal constant NATIVE_TOKEN_SYMBOL = 'Native';

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingWom; // 20.18 fixed point. Amount of pending wom
        //
        // We do some fancy math here. Basically, any point in time, the amount of WOMs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accWomPerShare + user.factor * pool.accWomPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWomPerShare`, `accWomPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfoV3 {
        IERC20 lpToken; // Address of LP token contract.
        ////
        IMultiRewarder rewarder; // This rewarder will be deprecated, please also refer to the mapping of boostedRewarders
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }

    uint256 public constant REWARD_DURATION = 7 days;
    uint256 public constant ACC_TOKEN_PRECISION = 1e12;
    uint256 public constant TOTAL_PARTITION = 1000;

    // Wom token
    IERC20 public wom;
    // Venom does not seem to hurt the Wombat, it only makes it stronger.
    IVeWom public veWom;
    // New Master Wombat address for future migrations
    IMasterWombatV3 newMasterWombat;
    // Address of Voter
    address public voter;
    // Base partition emissions (e.g. 300 for 30%).
    // BasePartition and boostedPartition add up to TOTAL_PARTITION (1000) for 100%
    uint16 public basePartition;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet internal lpTokens;
    /// @notice Info of each pool.
    /// @dev Note that `poolInfoV3[pid].rewarder` will be deprecated and it may co-exist with boostedRewarders[pid]
    PoolInfoV3[] public poolInfoV3;
    // userInfo[pid][user], Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Mapping of asset to pid. Offset by +1 to distinguish with default value
    mapping(address => uint256) internal assetPid;
    // pid => address of boostedRewarder
    mapping(uint256 => IBoostedMultiRewarder) public override boostedRewarders;

    IBribeRewarderFactory public bribeRewarderFactory;

    event Add(uint256 indexed pid, IERC20 indexed lpToken, IBoostedMultiRewarder boostedRewarder);
    event SetNewMasterWombat(IMasterWombatV3 masterWormbat);
    event SetBribeRewarderFactory(IBribeRewarderFactory bribeRewarderFactory);
    event SetRewarder(uint256 indexed pid, IMultiRewarder rewarder);
    event SetBoostedRewarder(uint256 indexed pid, IBoostedMultiRewarder boostedRewarder);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionPartition(address indexed user, uint256 basePartition, uint256 boostedPartition);
    event UpdateVeWOM(address indexed user, address oldVeWOM, address newVeWOM);
    event UpdateVoter(address indexed user, address oldVoter, address newVoter);
    event EmergencyWomWithdraw(address owner, uint256 balance);

    /// @dev Modifier ensuring that certain function can only be called by VeWom
    modifier onlyVeWom() {
        require(address(veWom) == msg.sender, 'MasterWombat: caller is not VeWom');
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by Voter
    modifier onlyVoter() {
        require(address(voter) == msg.sender, 'MasterWombat: caller is not Voter');
        _;
    }

    function initialize(IERC20 _wom, IVeWom _veWom, address _voter, uint16 _basePartition) external initializer {
        require(address(_wom) != address(0), 'wom address cannot be zero');
        require(_basePartition <= TOTAL_PARTITION, 'base partition must be in range 0, 1000');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        wom = _wom;
        veWom = _veWom;
        voter = _voter;
        basePartition = _basePartition;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterWombat(IMasterWombatV3 _newMasterWombat) external onlyOwner {
        newMasterWombat = _newMasterWombat;
        emit SetNewMasterWombat(_newMasterWombat);
    }

    function setBribeRewarderFactory(IBribeRewarderFactory _bribeRewarderFactory) external onlyOwner {
        bribeRewarderFactory = _bribeRewarderFactory;
        emit SetBribeRewarderFactory(_bribeRewarderFactory);
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _boostedRewarder the rewarder
    function add(IERC20 _lpToken, IBoostedMultiRewarder _boostedRewarder) external onlyOwner {
        require(Address.isContract(address(_lpToken)), 'add: LP token must be a valid contract');
        require(
            Address.isContract(address(_boostedRewarder)) || address(_boostedRewarder) == address(0),
            'add: boostedRewarder must be contract or zero'
        );
        require(!lpTokens.contains(address(_lpToken)), 'add: LP already added');

        // update PoolInfoV3 with the new LP
        poolInfoV3.push(
            PoolInfoV3({
                lpToken: _lpToken,
                lastRewardTimestamp: uint40(block.timestamp),
                accWomPerShare: 0,
                rewarder: IMultiRewarder(address(0)),
                accWomPerFactorShare: 0,
                sumOfFactors: 0,
                periodFinish: uint40(block.timestamp),
                rewardRate: 0
            })
        );
        uint256 pid = poolInfoV3.length - 1;
        assetPid[address(_lpToken)] = pid + 1; // offset by +1
        boostedRewarders[pid] = _boostedRewarder;

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(pid, _lpToken, _boostedRewarder);
    }

    /// @notice Update the given pool's boostedRewarder
    /// @param _pid the pool id
    /// @param _boostedRewarder the boostedRewarder
    function setBoostedRewarder(uint256 _pid, IBoostedMultiRewarder _boostedRewarder) external override {
        require(msg.sender == address(bribeRewarderFactory) || msg.sender == owner(), 'not authorized');
        require(
            Address.isContract(address(_boostedRewarder)) || address(_boostedRewarder) == address(0),
            'set: boostedRewarder must be contract or zero'
        );

        boostedRewarders[_pid] = _boostedRewarder;
        emit SetBoostedRewarder(_pid, _boostedRewarder);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IMultiRewarder _rewarder) external onlyOwner {
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'set: rewarder must be contract or zero'
        );

        PoolInfoV3 storage pool = poolInfoV3[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfoV3.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfoV3 storage pool = poolInfoV3[_pid];

        if (block.timestamp > pool.lastRewardTimestamp) {
            (uint256 accWomPerShare, uint256 accWomPerFactorShare) = calRewardPerUnit(_pid);
            pool.accWomPerShare = to104(accWomPerShare);
            pool.accWomPerFactorShare = to104(accWomPerFactorShare);
            pool.lastRewardTimestamp = uint40(lastTimeRewardApplicable(pool.periodFinish));

            // We can consider to skip this function to minimize gas
            // voter address can be zero during a migration. See comment in setVoter.
            if (voter != address(0)) {
                IVoter(voter).distribute(pool.lpToken);
            }
        }
    }

    /// @notice Distribute WOM over a period of 7 days
    /// @dev Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount) external override onlyVoter {
        require(_amount > 0, 'notifyRewardAmount: zero amount');

        // this line reverts if asset is not in the list
        uint256 pid = assetPid[_lpToken] - 1;
        PoolInfoV3 storage pool = poolInfoV3[pid];
        if (pool.lastRewardTimestamp >= pool.periodFinish) {
            pool.rewardRate = to128(_amount / REWARD_DURATION);
        } else {
            uint256 remainingTime = pool.periodFinish - pool.lastRewardTimestamp;
            uint256 leftoverReward = remainingTime * pool.rewardRate;
            pool.rewardRate = to128((_amount + leftoverReward) / REWARD_DURATION);
        }

        pool.lastRewardTimestamp = uint40(block.timestamp);
        pool.periodFinish = uint40(block.timestamp + REWARD_DURATION);

        // Event is not emitted as Voter should have already emitted it
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterWombat.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterWombat has stopped emisions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterWombat) != (address(0)), 'to where?');

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[pid];
                pool.lpToken.approve(address(newMasterWombat), user.amount);
                uint256 newPid = newMasterWombat.getAssetPid(address(pool.lpToken));
                newMasterWombat.depositFor(newPid, user.amount, msg.sender);

                pool.sumOfFactors -= user.factor;
                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for WOM allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(uint256 _pid, uint256 _amount, address _user) external override nonReentrant whenNotPaused {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        _updateUserAmount(_pid, _user, user.amount + _amount);

        // safe transfer is not needed for Asset
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for WOM allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // update pool in case user has deposited
        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount + _amount);

        // safe transfer is not needed for Asset
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(
        uint256[] calldata _pids
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards)
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(
        uint256[] memory _pids
    ) private returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards) {
        // accumulate rewards for each one of the pids in pending
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            _updatePool(_pids[i]);

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[_pids[i]];
                // increase pending to send all rewards once
                uint128 newRewardDebt = _getRewardDebt(
                    user.amount,
                    pool.accWomPerShare,
                    user.factor,
                    pool.accWomPerFactorShare
                );
                uint256 poolRewards = newRewardDebt + user.pendingWom - user.rewardDebt;

                user.pendingWom = 0;

                // update reward debt
                user.rewardDebt = newRewardDebt;

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if exist, update external rewarder
                IMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onReward(msg.sender, user.amount);
                }
                IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pids[i]];
                if (address(boostedRewarder) != address(0)) {
                    // update rewarders before we update lpSupply and sumOfFactors
                    additionalRewards[i] = boostedRewarder.onReward(msg.sender, user.amount, user.factor);
                }
            }
        }

        // transfer all rewards
        // SafeERC20 is not needed as WOM will revert if transfer fails
        wom.transfer(payable(msg.sender), reward);
    }

    /// @notice Withdraw LP tokens from MasterWombat.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, 'withdraw: not enough balance');

        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount - _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Update user balance and distribute WOM rewards
    function _updateUserAmount(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // Harvest WOM
        if (user.amount > 0 || user.pendingWom > 0) {
            reward =
                _getRewardDebt(user.amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare) +
                user.pendingWom -
                user.rewardDebt;
            user.pendingWom = 0;

            // SafeERC20 is not needed as WOM will revert if transfer fails
            wom.transfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update amount of lp staked
        uint256 oldUserAmount = user.amount;
        user.amount = to128(_amount);

        // update sumOfFactors
        uint256 oldFactor = user.factor;
        user.factor = to128(DSMath.sqrt(user.amount * veWom.balanceOf(_user), user.amount));

        // update reward debt
        user.rewardDebt = _getRewardDebt(_amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare);

        // update rewarder before we update lpSupply and sumOfFactors
        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = pool.rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                additionalRewards = boostedRewarder.onReward(_user, _amount, user.factor);
            } else if (address(boostedRewarder) == address(0)) {
                additionalRewards = rewarder.onReward(_user, _amount);
            } else {
                uint256[] memory temp1 = rewarder.onReward(_user, _amount);
                uint256[] memory temp2 = boostedRewarder.onReward(_user, _amount, user.factor);

                additionalRewards = concatArrays(temp1, temp2);
            }
        }

        pool.sumOfFactors = to128(pool.sumOfFactors + user.factor - oldFactor);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) external override nonReentrant {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // update rewarders before we update lpSupply and sumOfFactors
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(msg.sender, 0);
        }
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(boostedRewarder) != address(0)) {
            boostedRewarder.onReward(msg.sender, 0, 0);
        }

        // safe transfer is not needed for Asset
        uint256 oldUserAmount = user.amount;
        pool.lpToken.transfer(address(msg.sender), oldUserAmount);

        pool.sumOfFactors = pool.sumOfFactors - user.factor;

        user.amount = 0;
        user.factor = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);
    }

    /// @notice updates emission partition
    /// @param _basePartition the future base partition
    function updateEmissionPartition(uint16 _basePartition) external onlyOwner {
        require(_basePartition <= TOTAL_PARTITION);
        massUpdatePools();
        basePartition = _basePartition;
        emit UpdateEmissionPartition(msg.sender, _basePartition, TOTAL_PARTITION - _basePartition);
    }

    /// @notice updates veWom address
    /// @param _newVeWom the new VeWom address
    function setVeWom(IVeWom _newVeWom) external onlyOwner {
        require(address(_newVeWom) != address(0));
        IVeWom oldVeWom = veWom;
        veWom = _newVeWom;
        emit UpdateVeWOM(msg.sender, address(oldVeWom), address(_newVeWom));
    }

    /// @notice updates voter address
    /// @param _newVoter the new Voter address
    function setVoter(address _newVoter) external onlyOwner {
        // voter address can be zero during a migration. This is done to avoid
        // the scenario where both old and new MasterWombat claims in migrate,
        // which calls voter.distribute. But only one can succeed as voter.distribute
        // is only callable from gauge manager.
        address oldVoter = voter;
        voter = _newVoter;
        emit UpdateVoter(msg.sender, oldVoter, _newVoter);
    }

    /// @notice updates factor after any veWom token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVeWomBalance the amount of veWOM
    /// @dev can only be called by veWom
    function updateFactor(address _user, uint256 _newVeWomBalance) external override onlyVeWom {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfoV3.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount == 0) {
                continue;
            }

            // first, update pool
            _updatePool(pid);
            PoolInfoV3 storage pool = poolInfoV3[pid];

            // calculate pending
            uint256 pending = _getRewardDebt(user.amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare) -
                user.rewardDebt;
            // increase pendingWom
            user.pendingWom += to128(pending);

            // update boosted partition factor
            uint256 oldFactor = user.factor;
            uint256 newFactor = DSMath.sqrt(user.amount * _newVeWomBalance, user.amount);
            user.factor = to128(newFactor);
            // update reward debt, take into account newFactor
            user.rewardDebt = _getRewardDebt(user.amount, pool.accWomPerShare, newFactor, pool.accWomPerFactorShare);

            // update boostedRewarder before we update sumOfFactors
            IBoostedMultiRewarder boostedRewarder = boostedRewarders[pid];
            if (address(boostedRewarder) != address(0)) {
                boostedRewarder.onUpdateFactor(_user, user.factor);
            }

            // also, update sumOfFactors
            pool.sumOfFactors = to128(pool.sumOfFactors + newFactor - oldFactor);
        }
    }

    /// @notice In case we need to manually migrate WOM funds from MasterChef
    /// Sends all remaining wom from the contract to the owner
    function emergencyWomWithdraw() external onlyOwner {
        // safe transfer is not needed for WOM
        wom.transfer(address(msg.sender), wom.balanceOf(address(this)));
        emit EmergencyWomWithdraw(address(msg.sender), wom.balanceOf(address(this)));
    }

    /**
     * Read-only functions
     */

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(
        uint256 _pid
    ) public view override returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols) {
        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                bonusTokenAddresses = boostedRewarder.rewardTokens();
            } else if (address(boostedRewarder) == address(0)) {
                bonusTokenAddresses = rewarder.rewardTokens();
            } else {
                IERC20[] memory temp1 = rewarder.rewardTokens();
                IERC20[] memory temp2 = boostedRewarder.rewardTokens();

                bonusTokenAddresses = concatArrays(temp1, temp2);
            }
        }

        uint256 len = bonusTokenAddresses.length;
        bonusTokenSymbols = new string[](len);
        for (uint256 i; i < len; ++i) {
            if (address(bonusTokenAddresses[i]) == address(0)) {
                bonusTokenSymbols[i] = NATIVE_TOKEN_SYMBOL;
            } else {
                bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
            }
        }
    }

    function boostedPartition() external view returns (uint256) {
        return TOTAL_PARTITION - basePartition;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfoV3.length;
    }

    function getAssetPid(address asset) external view override returns (uint256) {
        uint256 pidBeforeOffset = assetPid[asset];
        if (pidBeforeOffset == 0) revert('invalid pid');
        // revert if asset not exist
        return pidBeforeOffset - 1;
    }

    function lastTimeRewardApplicable(uint256 _periodFinish) public view returns (uint256) {
        return block.timestamp < _periodFinish ? block.timestamp : _periodFinish;
    }

    function calRewardPerUnit(uint256 _pid) public view returns (uint256 accWomPerShare, uint256 accWomPerFactorShare) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        accWomPerShare = pool.accWomPerShare;
        accWomPerFactorShare = pool.accWomPerFactorShare;

        if (lpSupply == 0 || block.timestamp <= pool.lastRewardTimestamp) {
            // update only if now > lastRewardTimestamp
            return (accWomPerShare, accWomPerFactorShare);
        }

        uint256 secondsElapsed = lastTimeRewardApplicable(pool.periodFinish) - pool.lastRewardTimestamp;
        uint256 womReward = secondsElapsed * pool.rewardRate;
        accWomPerShare += (womReward * ACC_TOKEN_PRECISION * basePartition) / (lpSupply * TOTAL_PARTITION);

        if (pool.sumOfFactors != 0) {
            accWomPerFactorShare +=
                (womReward * ACC_TOKEN_PRECISION * (TOTAL_PARTITION - basePartition)) /
                (pool.sumOfFactors * TOTAL_PARTITION);
        }
    }

    /// @notice View function to see pending WOMs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        override
        returns (
            uint256 pendingRewards,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        )
    {
        // calculate accWomPerShare and accWomPerFactorShare
        (uint256 accWomPerShare, uint256 accWomPerFactorShare) = calRewardPerUnit(_pid);

        UserInfo storage user = userInfo[_pid][_user];
        pendingRewards =
            ((user.amount * accWomPerShare + user.factor * accWomPerFactorShare) / ACC_TOKEN_PRECISION) +
            user.pendingWom -
            user.rewardDebt;

        // If it's a double reward farm, return info about the bonus token
        (bonusTokenAddresses, bonusTokenSymbols) = rewarderBonusTokenInfo(_pid);

        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                pendingBonusRewards = boostedRewarder.pendingTokens(_user);
            } else if (address(boostedRewarder) == address(0)) {
                pendingBonusRewards = rewarder.pendingTokens(_user);
            } else {
                uint256[] memory temp1 = rewarder.pendingTokens(_user);
                uint256[] memory temp2 = boostedRewarder.pendingTokens(_user);

                pendingBonusRewards = concatArrays(temp1, temp2);
            }
        }
    }

    /// @notice [Deprecated] A backward compatible function to return the PoolInfo struct in MasterWombatV2
    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            IERC20 lpToken,
            uint96 allocPoint,
            IMultiRewarder rewarder,
            uint256 sumOfFactors,
            uint104 accWomPerShare,
            uint104 accWomPerFactorShare,
            uint40 lastRewardTimestamp
        )
    {
        PoolInfoV3 memory pool = poolInfoV3[_pid];

        return (
            pool.lpToken,
            0,
            pool.rewarder,
            pool.sumOfFactors,
            pool.accWomPerShare,
            pool.accWomPerFactorShare,
            pool.lastRewardTimestamp
        );
    }

    function getSumOfFactors(uint256 _pid) external view override returns (uint256) {
        return poolInfoV3[_pid].sumOfFactors;
    }

    function _getRewardDebt(
        uint256 amount,
        uint256 accWomPerShare,
        uint256 factor,
        uint256 accWomPerFactorShare
    ) internal pure returns (uint128) {
        return to128((amount * accWomPerShare + factor * accWomPerFactorShare) / ACC_TOKEN_PRECISION);
    }

    function concatArrays(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory returnArr) {
        returnArr = new uint256[](A.length + B.length);

        uint256 i;
        for (; i < A.length; i++) {
            returnArr[i] = A[i];
        }

        for (uint256 j; j < B.length; ) {
            returnArr[i++] = B[j++];
        }
    }

    function concatArrays(IERC20[] memory A, IERC20[] memory B) internal pure returns (IERC20[] memory returnArr) {
        returnArr = new IERC20[](A.length + B.length);

        uint256 i;
        for (; i < A.length; i++) {
            returnArr[i] = A[i];
        }

        for (uint256 j; j < B.length; ) {
            returnArr[i++] = B[j++];
        }
    }

    function to128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function to104(uint256 val) internal pure returns (uint104) {
        if (val > type(uint104).max) revert('uint104 overflow');
        return uint104(val);
    }
}

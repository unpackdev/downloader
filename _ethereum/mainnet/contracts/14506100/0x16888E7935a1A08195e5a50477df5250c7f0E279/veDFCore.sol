//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./LPTokenWrapper.sol";
import "./IStakedDF.sol";
import "./IRewardDistributor.sol";
import "./SafeRatioMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./IERC20Upgradeable.sol";

/**
 * @notice Minter of veDF
 * @dev The contract does not store parameters such as the number of SDFs
 */
contract veDFCore is
    Ownable,
    Initializable,
    ReentrancyGuardUpgradeable,
    LPTokenWrapper
{
    using SafeRatioMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStakedDF;

    ///@dev Min lock step (seconds of a week).
    uint256 internal constant MIN_STEP = 1 weeks;

    ///@dev Token of reward
    IERC20Upgradeable public rewardToken;
    IStakedDF public sDF;
    address public rewardDistributor;

    uint256 public rewardRate = 0;

    ///@dev The timestamp that started to distribute token reward.
    uint256 public startTime;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public lastRateUpdateTime;
    uint256 public rewardDistributedStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    ///@dev Due time of settlement to node
    uint256 public lastSettledTime;
    ///@dev Total overdue balance settled
    uint256 public accSettledBalance;

    struct SettleLocalVars {
        uint256 lastUpdateTime;
        uint256 lastSettledTime;
        uint256 accSettledBalance;
        uint256 rewardPerToken;
        uint256 rewardRate;
        uint256 totalSupply;
    }

    struct Node {
        uint256 rewardPerTokenSettled;
        uint256 balance;
    }

    ///@dev due time timestamp => data
    mapping(uint256 => Node) internal nodes;

    event RewardRateUpdated(uint256 oldRewardRate, uint256 newRewardRate);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    ///@dev Emitted when `create` is called.
    ///@param recipient Address of receiving veDF
    ///@param sDFLocked Number of locked sDF
    ///@param duration Lock duration
    ///@param veDFReceived Number of veDF received
    event Create(
        address recipient,
        uint256 sDFLocked,
        uint256 duration,
        uint256 veDFReceived
    );

    ///@dev Emitted when `refill` is called.
    ///@param recipient Address of receiving veDF
    ///@param sDFRefilled Increased number of sDF
    ///@param veDFReceived Number of veDF received
    event Refill(address recipient, uint256 sDFRefilled, uint256 veDFReceived);

    ///@dev Emitted when `extend` is called.
    ///@param recipient Address of receiving veDF
    ///@param preDueTime Old expiration time
    ///@param newDueTime New expiration time
    ///@param duration Lock duration
    ///@param veDFReceived Number of veDF received
    event Extend(
        address recipient,
        uint256 preDueTime,
        uint256 newDueTime,
        uint256 duration,
        uint256 veDFReceived
    );

    ///@dev Emitted when `refresh` is called.
    ///@param recipient Address of receiving veDF
    ///@param presDFLocked Old number of locked sDF
    ///@param newsDFLocked New number of locked sDF
    ///@param duration Lock duration
    ///@param preveDFBalance Original veDF balance
    ///@param newveDFBalance New of veDF balance
    event Refresh(
        address recipient,
        uint256 presDFLocked,
        uint256 newsDFLocked,
        uint256 duration,
        uint256 preveDFBalance,
        uint256 newveDFBalance
    );

    ///@dev Emitted when `withdraw` is called.
    ///@param recipient Address of receiving veDF
    ///@param veDFBurned Amount of veDF burned
    ///@param sDFRefunded Number of sDF returned
    event Withdraw(address recipient, uint256 veDFBurned, uint256 sDFRefunded);

    function initialize(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public virtual initializer {
        require(
            _startTime > block.timestamp,
            "veDFManager: Start time must be greater than the block timestamp"
        );

        __Ownable_init();
        __ReentrancyGuard_init();

        veDF = _veDF;
        sDF = _sDF;
        rewardToken = _rewardToken;
        startTime = _startTime;
        lastSettledTime = _startTime;
        lastUpdateTime = _startTime;
        rewardDistributor = _rewardDistributor;

        sDF.safeApprove(address(veDF), uint256(-1));
    }

    ///@notice Update distribution of historical nodes and users
    ///@dev Basically all operations will be called
    modifier updateReward(address _account) {
        if (startTime <= block.timestamp) {
            _settleNode(block.timestamp);
            if (_account != address(0)) {
                _updateUserReward(_account);
            }
        }
        _;
    }

    modifier updateRewardDistributed() {
        rewardDistributedStored = rewardDistributed();
        lastRateUpdateTime = block.timestamp;
        _;
    }

    modifier sanityCheck(uint256 _amount) {
        require(_amount != 0, "veDFManager: Stake amount can not be zero!");
        _;
    }

    ///@dev Check duetime rules
    modifier isDueTimeValid(uint256 _dueTime) {
        require(
            _dueTime > block.timestamp,
            "veDFManager: Due time must be greater than the current time"
        );
        require(
            _dueTime.sub(startTime).mod(MIN_STEP) == 0,
            "veDFManager: The minimum step size must be `MIN_STEP`"
        );
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            rewardDistributor == msg.sender,
            "veDFManager: caller is not the rewardDistributor"
        );
        _;
    }

    /*********************************/
    /******** Owner functions ********/
    /*********************************/

    ///@notice Set a new reward rate
    function setRewardRate(uint256 _rewardRate)
        external
        onlyRewardDistributor
        updateRewardDistributed
        updateReward(address(0))
    {
        uint256 _oldRewardRate = rewardRate;
        rewardRate = _rewardRate;

        emit RewardRateUpdated(_oldRewardRate, _rewardRate);
    }

    // This function allows governance to take unsupported tokens out of the
    // contract, since this one exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously
    // mess up. There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function rescueTokens(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) external onlyRewardDistributor {
        _token.safeTransfer(_to, _amount);
    }

    /*********************************/
    /****** Internal functions *******/
    /*********************************/

    ///@dev Update the expired lock of the history node and calculate the `rewardPerToken` at that time
    function _settleNode(uint256 _now) private {
        //Using local variables to save gas
        SettleLocalVars memory _var;
        _var.lastUpdateTime = lastUpdateTime;
        _var.lastSettledTime = lastSettledTime;
        _var.accSettledBalance = accSettledBalance;
        _var.rewardPerToken = rewardPerTokenStored;
        _var.rewardRate = rewardRate;
        _var.totalSupply = totalSupply;

        //Cycle through each node in the history
        while (_var.lastSettledTime < _now) {
            Node storage _node = nodes[_var.lastSettledTime];
            if (_node.balance > 0) {
                _var.rewardPerToken = _var.rewardPerToken.add(
                    _var
                        .lastSettledTime
                        .sub(_var.lastUpdateTime)
                        .mul(_var.rewardRate)
                        .rdiv(_var.totalSupply.sub(_var.accSettledBalance))
                );

                //After the rewardpertoken is settled, add the balance of this node to accsettledbalance
                _var.accSettledBalance = _var.accSettledBalance.add(
                    _node.balance
                );

                //Record node settlement results
                _node.rewardPerTokenSettled = _var.rewardPerToken;
                //The first settlement is the time from the last operation to the first one behind it,
                //and then updated to the next node time
                _var.lastUpdateTime = _var.lastSettledTime;
            }

            //If accsettledbalance and totalsupply are equal,
            //it is equivalent to all lock positions expire.
            if (_var.accSettledBalance == _var.totalSupply) {
                //At this time, update lastsettledtime, and then jump out of the loop
                _var.lastSettledTime = MIN_STEP
                    .sub(_now.sub(_var.lastSettledTime).mod(MIN_STEP))
                    .add(_now);
                break;
            }

            //Update to next node time
            _var.lastSettledTime += MIN_STEP;
        }

        accSettledBalance = _var.accSettledBalance;
        lastSettledTime = _var.lastSettledTime;

        rewardPerTokenStored = _var.totalSupply == _var.accSettledBalance
            ? _var.rewardPerToken
            : _var.rewardPerToken.add(
                _now.sub(_var.lastUpdateTime).mul(_var.rewardRate).rdiv(
                    _var.totalSupply.sub(_var.accSettledBalance)
                )
            );
        lastUpdateTime = _now;
    }

    ///@dev Update the reward of specific users
    function _updateUserReward(address _account) private {
        (uint32 _dueTime, , ) = veDF.getLocker(_account);
        uint256 _rewardPerTokenStored = rewardPerTokenStored;

        if (_dueTime > 0) {
            //If the user's lock expires, retrieve the rewardpertokenstored of the expired node
            if (_dueTime < block.timestamp) {
                _rewardPerTokenStored = nodes[_dueTime].rewardPerTokenSettled;
            }

            rewards[_account] = balances[_account]
                .rmul(
                    _rewardPerTokenStored.sub(userRewardPerTokenPaid[_account])
                )
                .add(rewards[_account]);
        }

        userRewardPerTokenPaid[_account] = _rewardPerTokenStored;
    }

    /*********************************/
    /******* Users functions *********/
    /*********************************/

    /**
     * @notice Lock StakedDF and harvest veDF.
     * @dev Create lock-up information and mint veDF on lock-up amount and duration.
     * @param _amount StakedDF token amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function create(uint256 _amount, uint256 _dueTime)
        public
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        uint256 _duration = _dueTime.sub(block.timestamp);
        sDF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _veDFAmount = veDF.create(msg.sender, _amount, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Create(msg.sender, _amount, _duration, _veDFAmount);
    }

    /**
     * @notice Increased locked staked sDF and harvest veDF.
     * @dev According to the expiration time in the lock information, the minted veDF.
     * @param _amount StakedDF token amount.
     */
    function refill(uint256 _amount)
        external
        sanityCheck(_amount)
        updateReward(msg.sender)
    {
        sDF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _veDFAmount = veDF.refill(msg.sender, _amount);

        (uint32 _dueTime, , ) = veDF.getLocker(msg.sender);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Refill(msg.sender, _amount, _veDFAmount);
    }

    /**
     * @notice Increase the lock duration and harvest veDF.
     * @dev According to the amount of locked StakedDF and expansion time, the minted veDF.
     * @param _dueTime new Due time timestamp, in seconds.
     */
    function extend(uint256 _dueTime)
        external
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        (uint32 _oldDueTime, , ) = veDF.getLocker(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        //Subtract the user balance of the original node
        nodes[_oldDueTime].balance = nodes[_oldDueTime].balance.sub(
            _oldBalance
        );

        uint256 _duration = _dueTime.sub(_oldDueTime);
        uint256 _veDFAmount = veDF.extend(msg.sender, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);

        //Add the user balance of the original node to the new node
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount).add(
            _oldBalance
        );

        emit Extend(msg.sender, _oldDueTime, _dueTime, _duration, _veDFAmount);
    }

    /**
     * @notice Lock Staked sDF and and update veDF balance.
     * @dev Update the lockup information and veDF balance, return the excess sDF to the user or receive transfer increased amount.
     * @param _amount StakedDF token new amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function refresh(uint256 _amount, uint256 _dueTime)
        external
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        nonReentrant
        updateReward(msg.sender)
    {
        (, , uint256 _lockedSDF) = veDF.getLocker(msg.sender);
        //If the new amount is greater than the original lock volume, the difference needs to be supplemented
        if (_amount > _lockedSDF) {
            sDF.safeTransferFrom(
                msg.sender,
                address(this),
                _amount.sub(_lockedSDF)
            );
        }

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _oldVEDFAmount = balances[msg.sender];
        uint256 _newVEDFAmount = veDF.refresh2(msg.sender, _amount, _duration);

        balances[msg.sender] = _newVEDFAmount;
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        totalSupply = totalSupply.add(_newVEDFAmount).sub(_oldVEDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_newVEDFAmount);
        accSettledBalance = accSettledBalance.sub(_oldVEDFAmount);

        emit Refresh(
            msg.sender,
            _lockedSDF,
            _amount,
            _duration,
            _oldVEDFAmount,
            _newVEDFAmount
        );
    }

    /**
     * @notice Unlock Staked sDF and burn veDF.
     * @dev Burn veDF and clear lock information.
     */
    function _withdraw2() internal {
        uint256 _burnVEDF = veDF.withdraw2(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        totalSupply = totalSupply.sub(_oldBalance);
        balances[msg.sender] = balances[msg.sender].sub(_oldBalance);

        //Since totalsupply is reduced and the operation must be performed after the lock expires,
        //accsettledbalance should be reduced at the same time
        accSettledBalance = accSettledBalance.sub(_oldBalance);

        emit Withdraw(msg.sender, _burnVEDF, _oldBalance);
    }

    ///@notice Extract reward
    function getReward() public virtual updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransferFrom(
                rewardDistributor,
                msg.sender,
                _reward
            );
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function exit() external {
        getReward();
        _withdraw2();
    }

    /*********************************/
    /******** Query function *********/
    /*********************************/

    function rewardPerToken()
        external
        updateReward(address(0))
        returns (uint256)
    {
        return rewardPerTokenStored;
    }

    function rewardDistributed() public view returns (uint256) {
        // Have not started yet
        if (block.timestamp < startTime) {
            return rewardDistributedStored;
        }

        return
            rewardDistributedStored.add(
                block
                    .timestamp
                    .sub(MathUpgradeable.max(startTime, lastRateUpdateTime))
                    .mul(rewardRate)
            );
    }

    function earned(address _account)
        public
        updateReward(_account)
        returns (uint256)
    {
        return rewards[_account];
    }

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @return Information of the locker.
     *         due time;
     *         Lock up duration;
     *         Lock up sDF amount;
     */
    function getLocker(address _lockerAddress)
        external
        view
        returns (
            uint32,
            uint32,
            uint96
        )
    {
        return veDF.getLocker(_lockerAddress);
    }

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @param _startTime Start time.
     * @param _dueTime Due time.
     * @param _duration Lock up duration.
     * @param _sDFAmount Lock up sDF amount.
     * @param _veDFAmount veDF amount.
     * @param _rewardAmount Reward amount.
     * @param _lockedStatus Locked status, 0: no lockup; 1: locked; 2: Lock expired.
     */
    function getLockerInfo(address _lockerAddress)
        external
        returns (
            uint32 _startTime,
            uint32 _dueTime,
            uint32 _duration,
            uint96 _sDFAmount,
            uint256 _veDFAmount,
            uint256 _stakedveDF,
            uint256 _rewardAmount,
            uint256 _lockedStatus
        )
    {
        (_dueTime, _duration, _sDFAmount) = veDF.getLocker(_lockerAddress);
        _startTime = _dueTime > _duration ? _dueTime - _duration : 0;

        _veDFAmount = veDF.balanceOf(_lockerAddress);

        _rewardAmount = earned(_lockerAddress);

        _lockedStatus = 2;
        if (_dueTime > block.timestamp) {
            _lockedStatus = 1;
            _stakedveDF = _veDFAmount;
        }
        if (_dueTime == 0) _lockedStatus = 0;
    }

    /**
     * @dev Calculate the expected amount of users.
     * @param _lockerAddress veDF locker address.
     * @param _amount StakedDF token amount.
     * @param _duration Duration, in seconds.
     * @return veDF amount.
     */
    function calcBalanceReceived(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256) {
        return veDF.calcBalanceReceived(_lockerAddress, _amount, _duration);
    }

    /**
     * @dev Calculate the expected annual interest rate of users.
     * @param _lockerAddress veDF locker address.
     * @return annual interest.
     */
    function estimateLockerAPY(address _lockerAddress)
        external
        updateReward(_lockerAddress)
        returns (uint256)
    {
        uint256 _totalSupply = totalSupply.sub(accSettledBalance);
        if (_totalSupply == 0) return 0;

        (uint256 _dueTime, , uint96 _sDFAmount) = veDF.getLocker(_lockerAddress);
        uint256 _principal = uint256(_sDFAmount);
        if (_dueTime <= block.timestamp || _principal == 0) return 0;

        uint256 _annualInterest = rewardRate
            .mul(balances[_lockerAddress])
            .mul(365 days)
            .div(_totalSupply);

        return _annualInterest.rdiv(_principal);
    }

    /**
     * @dev Query veDF lock information.
     * @return veDF total supply.
     *         Total locked sDF
     *         Total settlement due
     *         Reward rate per second
     */
    function getLockersInfo()
        external
        updateReward(address(0))
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            veDF.totalSupply(),
            sDF.balanceOf(address(veDF)),
            accSettledBalance,
            rewardRate
        );
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./IMasterChefV2.sol";
import "./ReentrancyGuard.sol";

contract CakePool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 shares; // number of shares for a user.
        uint256 lastDepositedTime; // keep track of deposited time for potential penalty.
        uint256 lastUserActionAmount; // keep track of token deposited at the last user action.
        uint256 lastUserActionTime; // keep track of the last user action time.
        uint256 lockStartTime; // lock start time.
        uint256 lockEndTime; // lock end time.
        uint256 userBoostedShare; // boost share, in order to give the user higher reward. The user only enjoys the reward, so the principal needs to be recorded as a debt.
        bool locked; //lock status.
        uint256 lockedAmount; // amount deposited during lock period.
    }

    IERC20 public immutable token; // staking token.
    IERC20 public immutable bbc; // earning token.

    IMasterChefV2 public immutable masterchefV2;

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public freePerformanceFeeUsers; // free performance fee users.
    mapping(address => bool) public freeWithdrawFeeUsers; // free withdraw fee users.
    mapping(address => bool) public freeOverdueFeeUsers; // free overdue fee users.

    uint256 public totalShares;
    address public admin;
    address public treasury;
    address public operator;
    uint256 public bbcPoolPID;
    uint256 public totalBoostDebt; // total boost debt.
    uint256 public totalLockedAmount; // total lock amount.

    uint256 public constant MAX_PERFORMANCE_FEE = 2000; // 20%
    uint256 public constant MAX_WITHDRAW_FEE = 500; // 5%
    uint256 public constant MAX_OVERDUE_FEE = 100 * 1e10; // 100%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 1 weeks; // 1 week
    uint256 public constant MIN_LOCK_DURATION = 1 weeks; // 1 week
    uint256 public constant MAX_LOCK_DURATION_LIMIT = 1000 days; // 1000 days
    uint256 public constant BOOST_WEIGHT_LIMIT = 5000 * 1e10; // 5000%
    uint256 public constant PRECISION_FACTOR = 1e12; // precision factor.
    uint256 public constant PRECISION_FACTOR_SHARE = 1e28; // precision factor for share.
    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT = 0.00001 ether;
    uint256 public UNLOCK_FREE_DURATION = 2 weeks; // 2 week
    uint256 public MAX_LOCK_DURATION = 365 days; // 365 days
    uint256 public DURATION_FACTOR = 365 days; // 365 days, in order to calculate user additional boost.
    uint256 public DURATION_FACTOR_OVERDUE = 90 days; // 90 days, in order to calculate overdue fee.
    uint256 public BOOST_WEIGHT = 2000 * 1e10; // 2000%
    uint256 public constant FEE_RATE_SCALE = 10000;

    uint256 public performanceFee = 200; // 2%
    uint256 public withdrawFee = 400; // 4%
    uint256 public overdueFee = 100 * 1e10; // 100%
    uint256 public withdrawFeePeriod = 72 hours; // 3 days

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 duration,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 amount);
    event Pause();
    event Unpause();
    event Init();
    event Lock(
        address indexed sender,
        uint256 lockedAmount,
        uint256 shares,
        uint256 lockedDuration,
        uint256 blockTimestamp
    );
    event Unlock(
        address indexed sender,
        uint256 amount,
        uint256 blockTimestamp
    );
    event NewAdmin(address admin);
    event NewTreasury(address treasury);
    event NewOperator(address operator);
    event FreeFeeUser(address indexed user, bool indexed free);
    event NewPerformanceFee(uint256 performanceFee);
    event NewWithdrawFee(uint256 withdrawFee);
    event NewOverdueFee(uint256 overdueFee);
    event NewWithdrawFeePeriod(uint256 withdrawFeePeriod);
    event NewMaxLockDuration(uint256 maxLockDuration);
    event NewDurationFactor(uint256 durationFactor);
    event NewDurationFactorOverdue(uint256 durationFactorOverdue);
    event NewUnlockFreeDuration(uint256 unlockFreeDuration);
    event NewBoostWeight(uint256 boostWeight);

    /**
     * @notice Constructor
     * @param _token: Staking token contract
     * @param _masterchefV2: MasterChefV2 contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     * @param _operator: address of operator
     * @param _pid: bbc pool ID in MasterChefV2
     */
    constructor(
        IERC20 _token,
        IMasterChefV2 _masterchefV2,
        address _admin,
        address _treasury,
        address _operator,
        uint256 _pid
    ) {
        require(address(_token) != address(0), "Invalid token");
        require(address(_masterchefV2) != address(0), "Invalid masterchefV2");
        require(_admin != address(0), "Invalid admin");
        require(_treasury != address(0), "Invalid treasury");
        require(_operator != address(0), "Invalid operator");
        token = _token;
        bbc = IERC20(_masterchefV2.BBC());
        masterchefV2 = _masterchefV2;
        admin = _admin;
        treasury = _treasury;
        operator = _operator;
        bbcPoolPID = _pid;
    }

    /**
     * @notice Deposits a dummy token to `MASTER_CHEF` MCV2.
     * It will transfer all the `dummyToken` in the msg sender address.
     * @param dummyToken The address of the token to be deposited into MCV2.
     */
    function init(IERC20 dummyToken, uint256 amount) public onlyOwner {
        uint256 balance = dummyToken.balanceOf(msg.sender);
        require(balance != 0, "Balance must exceed 0");
        if (amount == 0 || amount > balance) amount = balance;
        dummyToken.safeTransferFrom(msg.sender, address(this), amount);
        dummyToken.approve(address(masterchefV2), amount);
        masterchefV2.deposit(bbcPoolPID, amount);
        emit Init();
    }

    function close() public onlyOwner {
        masterchefV2.emergencyWithdraw(bbcPoolPID);
    }

    /**
     * @notice Checks if the msg.sender is the admin address.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /**
     * @notice Checks if the msg.sender is either the bbc owner address or the operator address.
     */
    modifier onlyOperatorOrBBCOwner(address _user) {
        require(
            msg.sender == _user || msg.sender == operator,
            "Not operator or bbc owner"
        );
        _;
    }

    /**
     * @notice Update user share When need to unlock or charges a fee.
     * @param _user: User address
     */
    function updateUserShare(address _user) internal virtual {
        UserInfo storage user = userInfo[_user];
        if (user.shares > 0) {
            if (user.locked) {
                // Calculate the user's current token amount and update related parameters.
                uint256 currentAmount = (balanceOf() * (user.shares)) /
                    totalShares -
                    user.userBoostedShare;
                totalBoostDebt -= user.userBoostedShare;
                user.userBoostedShare = 0;
                totalShares -= user.shares;
                //Charge a overdue fee after the free duration has expired.
                if (
                    !freeOverdueFeeUsers[_user] &&
                    ((user.lockEndTime + UNLOCK_FREE_DURATION) <
                        block.timestamp)
                ) {
                    uint256 earnAmount = currentAmount - user.lockedAmount;
                    uint256 overdueDuration = block.timestamp -
                        user.lockEndTime -
                        UNLOCK_FREE_DURATION;
                    if (overdueDuration > DURATION_FACTOR_OVERDUE) {
                        overdueDuration = DURATION_FACTOR_OVERDUE;
                    }
                    // Rates are calculated based on the user's overdue duration.
                    uint256 overdueWeight = (overdueDuration * overdueFee) /
                        DURATION_FACTOR_OVERDUE;
                    uint256 currentOverdueFee = (earnAmount * overdueWeight) /
                        PRECISION_FACTOR;
                    uint256 feeHalf = currentOverdueFee / 2;
                    bbc.safeTransfer(treasury, feeHalf);
                    bbc.safeTransfer(
                        address(0xdead),
                        currentOverdueFee - feeHalf
                    );
                    currentAmount -= currentOverdueFee;
                }
                // Recalculate the user's share.
                uint256 pool = balanceOf();
                uint256 currentShares;
                if (totalShares != 0) {
                    currentShares =
                        (currentAmount * totalShares) /
                        (pool - currentAmount);
                } else {
                    currentShares = currentAmount;
                }
                user.shares = currentShares;
                totalShares += currentShares;
                // After the lock duration, update related parameters.
                if (user.lockEndTime < block.timestamp) {
                    user.locked = false;
                    user.lockStartTime = 0;
                    user.lockEndTime = 0;
                    totalLockedAmount -= user.lockedAmount;
                    user.lockedAmount = 0;
                    emit Unlock(_user, currentAmount, block.timestamp);
                }
            } else if (!freePerformanceFeeUsers[_user]) {
                // Calculate Performance fee.
                uint256 totalAmount = (user.shares * balanceOf()) / totalShares;
                totalShares -= user.shares;
                user.shares = 0;
                uint256 earnAmount = totalAmount -
                    user.lastUserActionAmount;
                uint256 currentPerformanceFee = (earnAmount *
                    performanceFee) / FEE_RATE_SCALE;
                if (currentPerformanceFee > 0) {
                    bbc.safeTransfer(treasury, currentPerformanceFee);
                    totalAmount -= currentPerformanceFee;
                }
                // Recalculate the user's share.
                uint256 pool = balanceOf();
                uint256 newShares;
                if (totalShares != 0) {
                    newShares =
                        (totalAmount * totalShares) /
                        (pool - totalAmount);
                } else {
                    newShares = totalAmount;
                }
                user.shares = newShares;
                totalShares += newShares;
            }
        }
    }

    /**
     * @notice Unlock user bbc funds.
     * @dev Only possible when contract not paused.
     * @param _user: User address
     */
    function unlock(
        address _user
    ) public onlyOperatorOrBBCOwner(_user) whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[_user];
        require(
            user.locked && user.lockEndTime < block.timestamp,
            "Cannot unlock yet"
        );
        depositOperation(0, 0, _user);
    }

    /**
     * @notice Deposit funds into the BBC Pool.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in BBC)
     * @param _lockDuration: Token lock duration
     */
    function deposit(
        uint256 _amount,
        uint256 _lockDuration
    ) public whenNotPaused nonReentrant {
        require(_amount > 0 || _lockDuration > 0, "Nothing to deposit");
        depositOperation(_amount, _lockDuration, msg.sender);
    }

    /**
     * @notice The operation of deposite.
     * @param _amount: number of tokens to deposit (in BBC)
     * @param _lockDuration: Token lock duration
     * @param _user: User address
     */
    function depositOperation(
        uint256 _amount,
        uint256 _lockDuration,
        address _user
    ) internal virtual {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0 || _amount > 0) {
            require(_amount > MIN_DEPOSIT_AMOUNT, "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT");
        }
        // Calculate the total lock duration and check whether the lock duration meets the conditions.
        uint256 totalLockDuration = _lockDuration;
        uint256 userLockEndTime = user.lockEndTime;
        if (userLockEndTime >= block.timestamp) {
            // Adding funds during the lock duration is equivalent to re-locking the position, needs to update some variables.
            if (_amount > 0) {
                user.lockStartTime = block.timestamp;
                totalLockedAmount -= user.lockedAmount;
                user.lockedAmount = 0;
            }
            totalLockDuration += userLockEndTime - user.lockStartTime;
        }
        require(
            _lockDuration == 0 || totalLockDuration >= MIN_LOCK_DURATION,
            "Minimum lock period is one week"
        );
        require(
            totalLockDuration <= MAX_LOCK_DURATION,
            "Maximum lock period exceeded"
        );

        // Harvest tokens from Masterchef.
        harvest();

        // Handle stock funds.
        if (totalShares == 0) {
            uint256 stockAmount = bbc.balanceOf(address(this));
            bbc.safeTransfer(treasury, stockAmount);
        }
        // Update user share.
        updateUserShare(_user);

        // Update lock duration.
        if (_lockDuration > 0) {
            if (userLockEndTime < block.timestamp) {
                user.lockStartTime = block.timestamp;
                userLockEndTime = block.timestamp + _lockDuration;
            } else {
                userLockEndTime += _lockDuration;
            }
            user.locked = true;
            user.lockEndTime = userLockEndTime;
        }

        uint256 currentShares;
        uint256 currentAmount;
        uint256 userCurrentLockedBalance;
        uint256 pool = balanceOf();
        if (_amount > 0) {
            token.safeTransferFrom(_user, address(this), _amount);
            currentAmount = _amount;
        }

        // Calculate lock funds
        if (user.shares > 0 && user.locked) {
            userCurrentLockedBalance = (pool * user.shares) / totalShares;
            currentAmount += userCurrentLockedBalance;
            totalShares -= user.shares;
            user.shares = 0;

            // Update lock amount
            if (user.lockStartTime == block.timestamp) {
                user.lockedAmount = userCurrentLockedBalance;
                totalLockedAmount += userCurrentLockedBalance;
            }
        }
        if (totalShares != 0) {
            currentShares =
                (currentAmount * totalShares) /
                (pool - userCurrentLockedBalance);
        } else {
            currentShares = currentAmount;
        }

        // Calculate the boost weight share.
        if (userLockEndTime > user.lockStartTime) {
            // Calculate boost share.
            uint256 boostWeight = ((userLockEndTime - user.lockStartTime) *
                BOOST_WEIGHT) / DURATION_FACTOR;
            uint256 boostShares = (boostWeight * currentShares) /
                PRECISION_FACTOR;
            currentShares += boostShares;
            user.shares += currentShares;

            // Calculate boost share , the user only enjoys the reward, so the principal needs to be recorded as a debt.
            uint256 userBoostedShare = (boostWeight * currentAmount) /
                PRECISION_FACTOR;
            user.userBoostedShare += userBoostedShare;
            totalBoostDebt += userBoostedShare;

            // Update lock amount.
            user.lockedAmount += _amount;
            totalLockedAmount += _amount;

            emit Lock(
                _user,
                user.lockedAmount,
                user.shares,
                (userLockEndTime - user.lockStartTime),
                block.timestamp
            );
        } else {
            user.shares += currentShares;
        }

        if (_amount > 0 || _lockDuration > 0) {
            user.lastDepositedTime = block.timestamp;
        }
        totalShares += currentShares;

        user.lastUserActionAmount =
            (user.shares * balanceOf()) /
            totalShares -
            user.userBoostedShare;

        user.lastUserActionTime = block.timestamp;

        emit Deposit(
            _user,
            _amount,
            currentShares,
            _lockDuration,
            block.timestamp
        );
    }

    /**
     * @notice Withdraw funds from the BBC Pool.
     * @param _amount: Number of amount to withdraw
     */
    function withdrawByAmount(
        uint256 _amount
    ) public whenNotPaused nonReentrant {
        withdrawOperation(0, _amount);
    }

    /**
     * @notice Withdraw funds from the BBC Pool.
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public whenNotPaused nonReentrant {
        require(_shares > 0, "Nothing to withdraw");
        withdrawOperation(_shares, 0);
    }

    /**
     * @notice The operation of withdraw.
     * @param _shares: Number of shares to withdraw
     * @param _amount: Number of amount to withdraw
     */
	function withdrawOperation(uint256 _shares, uint256 _amount) internal virtual {
        UserInfo storage user = userInfo[msg.sender];
        if(_shares==0 && _amount > 0)
            require(_amount > MIN_WITHDRAW_AMOUNT, "Withdraw amount must be greater than MIN_WITHDRAW_AMOUNT");
        else
            require(_shares <= user.shares, "Withdraw amount exceeds balance");
        require(user.lockEndTime < block.timestamp, "Still in lock");

        // Calculate the percent of withdraw shares, when unlocking or calculating the Performance fee, the shares will be updated.
        uint256 currentShare = _shares;
        uint256 sharesPercent = (_shares * PRECISION_FACTOR_SHARE) /
            user.shares;

        // Harvest token from MasterchefV2.
        harvest();

        // Update user share.
        updateUserShare(msg.sender);

        if (_shares == 0 && _amount > 0) {
            uint256 pool = balanceOf();
            currentShare = (_amount * totalShares) / pool; // Calculate equivalent shares
            if (currentShare > user.shares) {
                currentShare = user.shares;
            }
        } else {
            currentShare =
                (sharesPercent * user.shares) /
                PRECISION_FACTOR_SHARE;
        }
        uint256 currentAmount = (balanceOf() * currentShare) / totalShares;
        user.shares -= currentShare;
        totalShares -= currentShare;

        // Calculate withdraw fee
        if (
            !freeWithdrawFeeUsers[msg.sender] &&
            (block.timestamp < user.lastDepositedTime + withdrawFeePeriod)
        ) {
            uint256 currentWithdrawFee = (currentAmount * withdrawFee) /
                FEE_RATE_SCALE;
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount -= currentWithdrawFee;
        }
        token.safeTransfer(msg.sender, currentAmount);

        if (user.shares > 0) {
            user.lastUserActionAmount =
                (user.shares * balanceOf()) /
                totalShares;
        } else {
            user.lastUserActionAmount = 0;
        }

        user.lastUserActionTime = block.timestamp;

        emit Withdraw(msg.sender, currentAmount, currentShare);
    }

    /**
     * @notice Withdraw all funds for a user
     */
    function withdrawAll() public {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Harvest pending BBC tokens from MasterChef
     */
    function harvest() internal returns (uint256) {
        uint256 pendingBBC = masterchefV2.pendingBBC(bbcPoolPID, address(this));
        if (pendingBBC > 0) {
            uint256 balBefore = bbc.balanceOf(address(this));
            masterchefV2.withdraw(bbcPoolPID, 0);
            uint256 balAfter = bbc.balanceOf(address(this));
            uint256 balInc = balAfter - balBefore;
            emit Harvest(msg.sender, balInc);
            return balInc;
        }
        return 0;
    }

    /**
     * @notice Set admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit NewTreasury(treasury);
    }

    /**
     * @notice Set operator address
     * @dev Callable by the contract owner.
     */
    function setOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "Cannot be zero address");
        operator = _operator;
        emit NewOperator(operator);
    }

    /**
     * @notice Set free performance fee address
     * @dev Only callable by the contract admin.
     * @param _user: User address
     * @param _free: true:free false:not free
     */
    function setFreePerformanceFeeUser(
        address _user,
        bool _free
    ) public onlyAdmin {
        require(_user != address(0), "Cannot be zero address");
        freePerformanceFeeUsers[_user] = _free;
        emit FreeFeeUser(_user, _free);
    }

    /**
     * @notice Set free overdue fee address
     * @dev Only callable by the contract admin.
     * @param _user: User address
     * @param _free: true:free false:not free
     */
    function setFreeOverdueFeeUser(address _user, bool _free) public onlyAdmin {
        require(_user != address(0), "Cannot be zero address");
        freeOverdueFeeUsers[_user] = _free;
        emit FreeFeeUser(_user, _free);
    }

    /**
     * @notice Set free withdraw fee address
     * @dev Only callable by the contract admin.
     * @param _user: User address
     * @param _free: true:free false:not free
     */
    function setFreeWithdrawFeeUser(address _user, bool _free) public onlyAdmin {
        require(_user != address(0), "Cannot be zero address");
        freeWithdrawFeeUsers[_user] = _free;
        emit FreeFeeUser(_user, _free);
    }

    /**
     * @notice Set performance fee
     * @dev Only callable by the contract admin.
     */
    function setPerformanceFee(uint256 _performanceFee) public onlyAdmin {
        require(
            _performanceFee <= MAX_PERFORMANCE_FEE,
            "performanceFee cannot be more than MAX_PERFORMANCE_FEE"
        );
        performanceFee = _performanceFee;
        emit NewPerformanceFee(performanceFee);
    }

    /**
     * @notice Set withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint256 _withdrawFee) public onlyAdmin {
        require(
            _withdrawFee <= MAX_WITHDRAW_FEE,
            "withdrawFee cannot be more than MAX_WITHDRAW_FEE"
        );
        withdrawFee = _withdrawFee;
        emit NewWithdrawFee(withdrawFee);
    }

    /**
     * @notice Set overdue fee
     * @dev Only callable by the contract admin.
     */
    function setOverdueFee(uint256 _overdueFee) public onlyAdmin {
        require(
            _overdueFee <= MAX_OVERDUE_FEE,
            "overdueFee cannot be more than MAX_OVERDUE_FEE"
        );
        overdueFee = _overdueFee;
        emit NewOverdueFee(_overdueFee);
    }

    /**
     * @notice Set withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) public onlyAdmin {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
        emit NewWithdrawFeePeriod(withdrawFeePeriod);
    }

    /**
     * @notice Set MAX_LOCK_DURATION
     * @dev Only callable by the contract admin.
     */
    function setMaxLockDuration(uint256 _maxLockDuration) public onlyAdmin {
        require(
            _maxLockDuration <= MAX_LOCK_DURATION_LIMIT,
            "MAX_LOCK_DURATION cannot be more than MAX_LOCK_DURATION_LIMIT"
        );
        MAX_LOCK_DURATION = _maxLockDuration;
        emit NewMaxLockDuration(_maxLockDuration);
    }

    /**
     * @notice Set DURATION_FACTOR
     * @dev Only callable by the contract admin.
     */
    function setDurationFactor(uint256 _durationFactor) public onlyAdmin {
        require(_durationFactor > 0, "DURATION_FACTOR cannot be zero");
        DURATION_FACTOR = _durationFactor;
        emit NewDurationFactor(_durationFactor);
    }

    /**
     * @notice Set DURATION_FACTOR_OVERDUE
     * @dev Only callable by the contract admin.
     */
    function setDurationFactorOverdue(
        uint256 _durationFactorOverdue
    ) public onlyAdmin {
        require(
            _durationFactorOverdue > 0,
            "DURATION_FACTOR_OVERDUE cannot be zero"
        );
        DURATION_FACTOR_OVERDUE = _durationFactorOverdue;
        emit NewDurationFactorOverdue(_durationFactorOverdue);
    }

    /**
     * @notice Set UNLOCK_FREE_DURATION
     * @dev Only callable by the contract admin.
     */
    function setUnlockFreeDuration(
        uint256 _unlockFreeDuration
    ) public onlyAdmin {
        require(_unlockFreeDuration > 0, "UNLOCK_FREE_DURATION cannot be zero");
        UNLOCK_FREE_DURATION = _unlockFreeDuration;
        emit NewUnlockFreeDuration(_unlockFreeDuration);
    }

    /**
     * @notice Set BOOST_WEIGHT
     * @dev Only callable by the contract admin.
     */
    function setBoostWeight(uint256 _boostWeight) public onlyAdmin {
        require(
            _boostWeight <= BOOST_WEIGHT_LIMIT,
            "BOOST_WEIGHT cannot be more than BOOST_WEIGHT_LIMIT"
        );
        BOOST_WEIGHT = _boostWeight;
        emit NewBoostWeight(_boostWeight);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the BBC Pool
     */
    function inCaseTokensGetStuck(address _token) public onlyAdmin {
        require(
            _token != address(token),
            "Token cannot be same as deposit token"
        );

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Trigger stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() public onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Return to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() public onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Calculate Performance fee.
     * @param _user: User address
     * @return Returns Performance fee.
     */
    function calculatePerformanceFee(
        address _user
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (
            user.shares > 0 && !user.locked && !freePerformanceFeeUsers[_user]
        ) {
            uint256 earnAmount = getProfit(_user);
            uint256 currentPerformanceFee = (earnAmount * performanceFee) /
                FEE_RATE_SCALE;
            return currentPerformanceFee;
        }
        return 0;
    }

    /**
     * @notice Calculate overdue fee.
     * @param _user: User address
     * @return Returns Overdue fee.
     */
    function calculateOverdueFee(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (
            user.shares > 0 &&
            user.locked &&
            !freeOverdueFeeUsers[_user] &&
            ((user.lockEndTime + UNLOCK_FREE_DURATION) < block.timestamp)
        ) {
            uint256 earnAmount = getProfit(_user);
            uint256 overdueDuration = block.timestamp -
                user.lockEndTime -
                UNLOCK_FREE_DURATION;
            if (overdueDuration > DURATION_FACTOR_OVERDUE) {
                overdueDuration = DURATION_FACTOR_OVERDUE;
            }
            // Rates are calculated based on the user's overdue duration.
            uint256 overdueWeight = (overdueDuration * overdueFee) /
                DURATION_FACTOR_OVERDUE;
            uint256 currentOverdueFee = (earnAmount * overdueWeight) /
                PRECISION_FACTOR;
            return currentOverdueFee;
        }
        return 0;
    }

    /**
     * @notice Calculate Performance Fee Or Overdue Fee
     * @param _user: User address
     * @return Returns  Performance Fee Or Overdue Fee.
     */
    function calculatePerformanceFeeOrOverdueFee(
        address _user
    ) internal view returns (uint256) {
        return calculatePerformanceFee(_user) + calculateOverdueFee(_user);
    }

    /**
     * @notice Calculate withdraw fee.
     * @param _user: User address
     * @param _shares: Number of shares to withdraw
     * @return Returns Withdraw fee.
     */
    function calculateWithdrawFee(
        address _user, 
        uint256 _shares
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares < _shares) {
            _shares = user.shares;
        }
        if (!freeWithdrawFeeUsers[msg.sender] && !user.locked && (block.timestamp < user.lastDepositedTime + withdrawFeePeriod)) {
            uint256 pool = balanceOf() + calculateTotalPendingBBCRewards();
            uint256 sharesPercent = (_shares * PRECISION_FACTOR) / user.shares;
            uint256 currentTotalAmount = (pool * (user.shares)) /
                totalShares -
                user.userBoostedShare -
                calculatePerformanceFeeOrOverdueFee(_user);
            uint256 currentAmount = (currentTotalAmount * sharesPercent) / PRECISION_FACTOR;
            uint256 currentWithdrawFee = (currentAmount * withdrawFee) / FEE_RATE_SCALE;
            return currentWithdrawFee;
        }
        return 0;
    }

    /**
     * @notice Calculates the total pending rewards that can be harvested
     * @return Returns total pending bbc rewards
     */
    function calculateTotalPendingBBCRewards() public view returns (uint256) {
        uint256 amount = masterchefV2.pendingBBC(bbcPoolPID, address(this));
        return amount;
    }

    function getPricePerFullShare() public virtual view returns (uint256) {
        return
            totalShares == 0
                ? 1e18
                : ((balanceOf() + calculateTotalPendingBBCRewards()) * 1e18 / totalShares);
    }

    function getProfit(address _user) public virtual view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0) return 0;
        uint256 pool = balanceOf() + calculateTotalPendingBBCRewards();
        if (user.locked) {
            uint256 currentAmount = (pool * user.shares) /
                totalShares -
                user.userBoostedShare;
            return currentAmount - user.lockedAmount;
        }
        return
            (user.shares * pool) / totalShares - user.lastUserActionAmount;
    }

    /**
     * @notice Current pool available balance
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying bbcs
     * @dev It includes bbcs held by the contract and the boost debt amount.
     */
    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this)) + totalBoostDebt;
    }
}

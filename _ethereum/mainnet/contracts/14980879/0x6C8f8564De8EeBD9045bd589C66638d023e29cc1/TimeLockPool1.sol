// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BasePool.sol";
import "./ITimeLockPool.sol";
import "./Initializable.sol";

contract TimeLockPool1 is Initializable, BasePool, ITimeLockPool {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public withdrawalsPaused;
    bool public depositsPaused;
    
    uint256 public constant MIN_LOCK_DURATION = 7 days; // 7 days
    uint256 private constant BP = 1e19;
    uint256 public pauseWithdrawalsPercent;
    uint256 public pauseId;
    uint256 public maxBonus;
    uint256 public maxLockDuration;
    uint256 public rewardRate; // Max reward per second
    uint256 public lastUpdateTime; // Last time the rewards per token stored were updated
    uint256 public rewardPerTokenStored; // Rewards for each token, depends on the total boosted supply
    uint256 public staking_token_supply; // Total supply of staked FTs
    uint256 public staking_token_boosted_supply; // Total supply with multiplier
    uint256 public totalOwed;
    address public escrow;

    uint256[] public adminWithdrawalDates; // Dates of the admin withdrawals
    
    mapping(address => uint256) public rewards; // Stores the pending rewards
    mapping(address => uint256) public userRewardPerTokenPaid; // Last RewardPerToken used for this address
    mapping(address => uint256) public locked_balances; // Amount of FTs stored per staker
    mapping(address => uint256) public boosted_balances; // Amount of FTs with multiplier per staker
    mapping(uint256 => mapping(address => uint256)) public initialBalanceWhenPaused;
    mapping(uint256 => mapping(address => uint256)) public userWithdrawalsWhenPaused;
    mapping(uint256 => WithdrawalData) public adminWithdrawals; // Withdrawal data of a specific date
    mapping(address => ITimeLockPool.Deposit[]) public depositsOf;

    struct WithdrawalData {
        uint256 date;
        uint256 owedAmount;
        uint256 lessPerToken;
    }

    struct AdminDeposit {
        uint256 date;
        uint256 plusPerToken;
        uint256 withdrawalIdPaid;
    }

    function initialize(
        address _depositToken,
        address _rewardToken,
        address _veAnzenToken,
        uint256 _maxBonus,
        uint256 _maxLockDuration,
        uint256 _pauseWithdrawalsPercent,
        uint256 _rewardRate,
        address _escrow
    ) public initializer {
        __BasePool_init(
            _depositToken,
            _rewardToken,
            _veAnzenToken
        );
        require(
            _maxLockDuration >= MIN_LOCK_DURATION,
            "TimeLockPool.constructor: max lock duration must be greater or equal to mininmum lock duration"
        );
        require(_escrow != address(0), "TimeLockPool.constructor: escrow address is required");
        maxBonus = _maxBonus;
        maxLockDuration = _maxLockDuration;
        pauseWithdrawalsPercent = _pauseWithdrawalsPercent;
        lastUpdateTime = block.timestamp;
        rewardRate = _rewardRate;
        escrow = _escrow;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    /* ========== EVENTS ========== */
    event Deposited(
        uint256 amount,
        uint256 duration,
        address indexed receiver,
        address indexed from
    );
    event Withdrawn(
        uint256 indexed depositId,
        address indexed receiver,
        address indexed from,
        uint256 amount
    );
    event Recovered(address tokenAddress, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    // Allows to deposit an amount of deposit tokens inside the pool for some time to obtain rewards
    function deposit(uint256 _amount, uint256 _duration, address _receiver) external override updateReward(_receiver) {
        require(depositsPaused == false, "TimeLockPool.deposit: the deposits are paused");
        require(_amount > 0, "TimeLockPool.deposit: cannot deposit 0");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(MIN_LOCK_DURATION);

        depositToken.safeTransferFrom(_msgSender(), escrow, _amount);

        // Storing the new deposit data of the user
        depositsOf[_receiver].push();
        ITimeLockPool.Deposit storage _deposit = depositsOf[_receiver][depositsOf[_receiver].length-1];
        _deposit.kek_id = keccak256(abi.encodePacked(_receiver, block.timestamp, _amount));
        _deposit.amount = _amount;
        _deposit.multiplier = getMultiplier(duration);
        _deposit.start = uint64(block.timestamp);
        _deposit.end = uint64(block.timestamp) + uint64(duration);
        _deposit.accUserWithdrawal = 0;
        _deposit.changes.push(ITimeLockPool.DepositChange(block.timestamp, 0, _amount));

        // Getting multiplier amount
        uint256 boostedAmount = (_amount * getMultiplier(duration)) / 1e18;

        // Staking token supply and boosted supply
        staking_token_supply += _amount;
        staking_token_boosted_supply += boostedAmount;

        // Staking token balance and boosted balance
        locked_balances[_receiver] += _amount;
        boosted_balances[_receiver] += boostedAmount;

        // Gives vote tokens to the staker
        veAnzenToken.mint(_receiver, boostedAmount);

        emit Deposited(_amount, duration, _receiver, _msgSender());
    }

    // Allows a user to unstake many deposits in a single transaction
    // The depositIds should be sorted from the smallest to largest
    function batchWithdraw(
        uint256[] memory _depositIds,
        address[] memory _receivers,
        uint256[] memory _amounts
    ) external {
        require(
            _depositIds.length == _receivers.length && 
            _depositIds.length == _amounts.length,
             "Invalid inputs length"
        );
        for(uint256 i = _depositIds.length-1; i >= 0; i--){
            withdraw(_depositIds[i], _receivers[i], _amounts[i]);
            if(i==0) return;
        }
    }

    // Allows a user to unstake a deposit, it can be a partial amount of the total deposited amount 
        function withdraw(
        uint256 _depositId,
        address _receiver,
        uint256 _amount
    ) public updateReward(_msgSender()){

        ITimeLockPool.Deposit storage userDeposit = depositsOf[_msgSender()][
            _depositId
        ];

        require(
            _amount != 0 && _amount <= userDeposit.amount,
            "TimeLockPool.withdraw: Not valid amount"
        );

        (uint256 totalWithdrawable, uint256 lastTotalBeforeLessPerToken, uint256 lastAdminWithdrawalIndex, bool indexChanged) = _getWithdrawableAmount(_depositId, _msgSender());
        require(_amount <= totalWithdrawable, "TimeLockPool.withdraw: Insufficient withdrawable amount");

        // Accumulates the user withdrawals after the same adminWithdrawal
        if(indexChanged){
            userDeposit.accUserWithdrawal += _amount;
        } else {
            userDeposit.accUserWithdrawal = _amount;
        }

        _verifyWithdrawablePaused(totalWithdrawable, _amount);

        uint256 boostedAmount = (_amount * userDeposit.multiplier) / 1e18;

        // Removes the stake from the array
        if (_amount == userDeposit.amount) {
            depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][
                depositsOf[_msgSender()].length - 1
            ];
            depositsOf[_msgSender()].pop();
        } else {
            // Updating the last values for next user withdrawal
            userDeposit.amount -= _amount;
            userDeposit.changes.push(ITimeLockPool.DepositChange({
                date: block.timestamp, 
                previousLastAdminWithdrawalIndex: lastAdminWithdrawalIndex,
                previousLastTotalBeforeLessPerToken: lastTotalBeforeLessPerToken
            }));
        }

        // Claiming rewards
        getReward();

        // Burn pool shares
        veAnzenToken.burn(_msgSender(), boostedAmount);

        // Staking token balance and boosted balance
        locked_balances[_msgSender()] -= _amount;
        boosted_balances[_msgSender()] -= boostedAmount;

        // Staking token supply and boosted supply
        staking_token_supply -= _amount;
        staking_token_boosted_supply -= boostedAmount;

        // Send the amount or the remainder to avoid issues with decimals
        require(depositToken.balanceOf(escrow) > (_amount - 10000 wei), "TimeLockPool.withdraw: insufficient amount to pay");
        uint256 amountToSend = depositToken.balanceOf(escrow).min(_amount);

        // Return tokens to the user
        depositToken.safeTransferFrom(escrow, _receiver, amountToSend);
        emit Withdrawn(_depositId, _receiver, _msgSender(), amountToSend);
    }

    
    // Allows a user to claim his obtained rewards until the moment, it claims the rewards of all the deposits.
    function getReward() public updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardToken.safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    // Allows the admin to change the pause withdrawal percent
    function setPauseWithdrawalsPercent(uint256 _newPauseWithdrawalsPercent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pauseWithdrawalsPercent = _newPauseWithdrawalsPercent;
    }

    // Allows the admin to enable or disable the pause withdrawl percentage limit
    function toggleWithdrawals() external onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawalsPaused = !withdrawalsPaused;
        pauseId++;
    }

    // Allows the admin to enable or disable the pause for the deposits
    function toggleDeposits() external onlyRole(DEFAULT_ADMIN_ROLE) {
        depositsPaused = !depositsPaused;
    }

    // Returns the multiplier or booster that a deposited amount could use according to the duration of the deposit.
    function getMultiplier(uint256 _lockDuration)
        public
        view
        override
        returns (uint256)
    {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    // Gets the list of all the deposits a user has active
    function getDepositsOf(address _account)
        public
        view
        override
        returns (ITimeLockPool.Deposit[] memory)
    {
        return depositsOf[_account];
    }
    
    // Gets the amount of deposits a user has active
    function getDepositsOfLength(address _account)
        public
        view
        override
        returns (uint256)
    {
        return depositsOf[_account].length;
    }

    // Gets the maximum extra bonus that a user can get.
    function getMaxBonus() external view override returns (uint256) {
        return maxBonus;
    }

    // Gets the maximum extra bonus that a user can get.
    function getMaxLockDuration() external view override returns (uint256) {
        return maxLockDuration;
    }

    // Estimates the rewards per token obtained since the last update and according to the total supply 
    function rewardPerToken() internal view returns (uint256) {
        if (staking_token_supply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (
            (block.timestamp - lastUpdateTime) * rewardRate * 1e18 / staking_token_boosted_supply
        );
    }

    // Calculates the earned rewards for a user until the moment, including all his deposits
    function earned(address account) public view returns (uint256) {
        return boosted_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    // Added to support recovering LP Rewards from other systems to be distributed to holders. Allows the admin to withdraw any stuck tokens in the contract. But not the staking token, it is meant to be used for other tokens.
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Admin cannot withdraw the staking token from the contract
        require(tokenAddress != address(depositToken));
        IERC20Upgradeable(tokenAddress).safeTransfer(_msgSender(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }

    // Shows the current amount of deposited tokens in this pool
    function adminWithdrawableAmount() external view returns (uint256){
        return staking_token_supply - totalOwed;
    }

    // Allows the admin to withdraw the deposited tokens
    function adminWithdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        require(staking_token_supply - totalOwed >= amount, "Inssufficient locked tokens");
        adminWithdrawalDates.push(block.timestamp);
        uint256 lessPerToken = amount * BP / (staking_token_supply - totalOwed);  
        adminWithdrawals[block.timestamp] = WithdrawalData(block.timestamp, amount, lessPerToken);
        totalOwed += amount;
        depositToken.safeTransferFrom(escrow, _msgSender(), amount);
        return adminWithdrawalDates.length-1; // withdrawal ID
    }

    // Allows the redeposit the withdrawn tokens
    function refundLastWithdrawal(uint256 receivedAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receivedAmount > 0, "Received amount cannot be 0");
        require(totalOwed >= receivedAmount, "Received amount cannot be greater than total owed");

        // Gets the last withdrawal
        WithdrawalData storage data = adminWithdrawals[adminWithdrawalDates[adminWithdrawalDates.length-1]];

        if(receivedAmount >= data.owedAmount){
            depositToken.safeTransferFrom(_msgSender(), escrow, data.owedAmount);
            data.lessPerToken = 0;
            data.owedAmount = 0;
        } else {
            uint256 depositedPercentage = receivedAmount * BP / data.owedAmount;
            data.lessPerToken -= data.lessPerToken * depositedPercentage / BP;
            data.owedAmount -= receivedAmount;
            depositToken.safeTransferFrom(_msgSender(), escrow, data.owedAmount);
        }
        totalOwed -= receivedAmount;
    }
    
    // The input is the block number of the withdrawal data
    function getWithdrawalData(uint256 withdrawalBlockNumber) public view returns (WithdrawalData memory){
        return adminWithdrawals[withdrawalBlockNumber];
    }

    // Returns the length of the admin withdrawal
    function getAdminWithdrawalsLength() public view returns (uint256){
        return (adminWithdrawalDates.length);
    }

    // Returns the data of the last admin withdrawal
    function getLastAdminWithdrawalData() public view returns (WithdrawalData memory){
        require(adminWithdrawalDates.length == 0, "There are no withdrawals");
        return adminWithdrawals[adminWithdrawalDates.length-1];
    }

    // Returns the current withdrawable amount of an specific deposit id
    // It includes the pause in the deposit if this is enabled
    function withdrawableDepositedAmount(uint256 _depositId, address _account) public view returns (uint256){
         (uint256 totalWithdrawable,,,) = _getWithdrawableAmount(_depositId, _account);

        if (!withdrawalsPaused) return totalWithdrawable;

        uint256 pausedAmount = initialBalanceWhenPaused[pauseId][_account];
        if (pausedAmount == 0) pausedAmount = totalWithdrawable;
        
        uint256 maxWithdrawableAmount = pausedAmount -
            (pausedAmount * pauseWithdrawalsPercent) / BP;
        
        return maxWithdrawableAmount - userWithdrawalsWhenPaused[pauseId][_account];
    }

    // Calculates the withdrawable amount by a specific user depositId, also returns other values that help in the calculations for the next withdrawable amount
    function _getWithdrawableAmount(uint256 _depositId, address _account) private view returns (uint256, uint256, uint256, bool){
        
        require(
            _depositId < depositsOf[_account].length,
            "TimeLockPool.withdraw: ITimeLockPool.Deposit does not exist"
        );

        ITimeLockPool.Deposit memory userDeposit = depositsOf[_account][
            _depositId
        ];

        require(
            block.timestamp >= userDeposit.end,
            "TimeLockPool.withdraw: Stake is still locked!"
        );
        
        DepositChange memory change = userDeposit.changes[userDeposit.changes.length-1];

        uint256 lastAdminWithdrawalIndex;
        uint256 totalWithdrawable = change.previousLastTotalBeforeLessPerToken;
        uint256 lastTotalBeforeLessPerToken;

        bool foundAdminWithdrawal;
        for(uint256 i = change.previousLastAdminWithdrawalIndex; i < adminWithdrawalDates.length; i++){
            // If this is the first user withdrawal, and the current admin withdrawal ocurred before the deposit, continue
            if(userDeposit.changes.length == 1 && change.date > adminWithdrawalDates[i]) continue;
            foundAdminWithdrawal = true;
            
            // Values that will be used for the next user withdrawal
            lastTotalBeforeLessPerToken = totalWithdrawable;
            lastAdminWithdrawalIndex = i;

            totalWithdrawable -=  totalWithdrawable * adminWithdrawals[adminWithdrawalDates[i]].lessPerToken / BP;

            // Disccount the accumulated amount on the first iteration
            if(i == change.previousLastAdminWithdrawalIndex){
                totalWithdrawable -= userDeposit.accUserWithdrawal; // Accumulated withdrawn
            }
        }

        // It did not find any admin withdrawals, so here it fills the values that should be used
        if(!foundAdminWithdrawal){
            lastTotalBeforeLessPerToken = totalWithdrawable;
            totalWithdrawable -= userDeposit.accUserWithdrawal; // Accumulated withdrawn
            lastAdminWithdrawalIndex = change.previousLastAdminWithdrawalIndex;
        }
        // Indicates if the he admin withdrawal index has changed
        bool indexChanged = lastAdminWithdrawalIndex == change.previousLastAdminWithdrawalIndex;

        return (totalWithdrawable, lastTotalBeforeLessPerToken, lastAdminWithdrawalIndex, indexChanged);
    }

    // This function validates that the user does not withdraw more than the percentage on pause
    function _verifyWithdrawablePaused(uint256 totalWithdrawable, uint256 _amount) private {
        if (withdrawalsPaused == true) {
            if (initialBalanceWhenPaused[pauseId][_msgSender()] == 0) {
                initialBalanceWhenPaused[pauseId][_msgSender()] = totalWithdrawable;
            }
            uint256 maxWithdrawableAmount = initialBalanceWhenPaused[pauseId][_msgSender()] -
                (initialBalanceWhenPaused[pauseId][_msgSender()] * pauseWithdrawalsPercent) / BP;

            userWithdrawalsWhenPaused[pauseId][_msgSender()] += _amount;

            require(
                userWithdrawalsWhenPaused[pauseId][_msgSender()] <=
                    maxWithdrawableAmount,
                "TimeLockPool.withdraw: Withdrawals paused, too much to withdraw"
            );
        }
    }

    // Allows the admin to change the reward rate to be used in the formula to calculate rewards.
    function setRewardRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) updateReward(address(0)){
        rewardRate = newRate;
    }

    // Allows the admin to change the escrow account
    function setEscrowAccount(address newEscrow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newEscrow != address(0), "TimeLockPool.setEscrowAccount: invalid escrow address");
        escrow = newEscrow;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}

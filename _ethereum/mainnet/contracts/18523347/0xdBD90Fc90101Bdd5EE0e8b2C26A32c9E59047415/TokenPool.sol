// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

import "./IERC20Metadata.sol";
import "./CakePool.sol";

contract TokenPool is CakePool {
    using SafeERC20 for IERC20;


    mapping(address => uint256) public userRewardDebt;
    mapping(address => uint256) public userRewardPending;

    uint256 public totalStakedAmount; // total stake amount.
    uint256 private bbcPerShare;
    uint8 private immutable tokenDecimals;

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
    ) CakePool(_token, _masterchefV2, _admin, _treasury, _operator, _pid) {
        require(address(_token) != address(bbc), "Invalid token");
        tokenDecimals = IERC20Metadata(address(_token)).decimals();
        require(tokenDecimals<=18, "Unsupported decimals");
    }

    function toEther(uint256 _amount) internal view returns(uint256) {
        if(tokenDecimals < 18)
            return _amount * 10 ** (18 - tokenDecimals);
        else if(tokenDecimals > 18)
            return _amount / 10 ** (tokenDecimals - 18);
        return _amount;
    }
    
    function fromEther(uint256 _amount) internal view returns(uint256) {
        if(tokenDecimals < 18)
            return _amount / 10 ** (18 - tokenDecimals);
        else if(tokenDecimals > 18)
            return _amount * 10 ** (tokenDecimals - 18);
        return _amount;
    }

    /**
     * @notice Update user share when need to unlock or charges a fee.
     * @param _user: User address
     */
    function updateUserShare(address _user) internal override {
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
                    uint256 earnAmount = userRewardPending[_user];
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
                    userRewardPending[_user] -= currentOverdueFee;
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
                uint256 earnAmount = userRewardPending[_user];
                uint256 currentPerformanceFee = (earnAmount *
                    performanceFee) / FEE_RATE_SCALE;
                if (currentPerformanceFee > 0) {
                    bbc.safeTransfer(treasury, currentPerformanceFee);
                    userRewardPending[_user] -= currentPerformanceFee;
                }
            }
        }
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
    ) internal override {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0 || _amount > 0) {
            require(toEther(_amount) > MIN_DEPOSIT_AMOUNT, "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT");
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
        uint256 harvestedAmount = harvest();

        // Handle stock funds.
        if (totalShares == 0) {
            uint256 stockAmount = bbc.balanceOf(address(this));
            bbc.safeTransfer(treasury, stockAmount);
            harvestedAmount = 0;
        } else {
            bbcPerShare += (harvestedAmount * 1 ether) / totalShares;
            if (user.shares > 0) {
                userRewardPending[_user] +=
                    (bbcPerShare * user.shares) /
                    1 ether -
                    userRewardDebt[_user];
            }
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
                totalLockedAmount += user.lockedAmount;
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

        userRewardDebt[_user] = (bbcPerShare * user.shares) / 1 ether;
        totalStakedAmount += _amount;

        emit Deposit(
            _user,
            _amount,
            currentShares,
            _lockDuration,
            block.timestamp
        );
    }

    /**
     * @notice The operation of withdraw.
     * @param _shares: Number of shares to withdraw
     * @param _amount: Number of amount to withdraw
     */
    function withdrawOperation(uint256 _shares, uint256 _amount) internal override {
        UserInfo storage user = userInfo[msg.sender];
        if(_shares==0 && _amount > 0)
            require(toEther(_amount) > MIN_WITHDRAW_AMOUNT, "Withdraw amount must be greater than MIN_WITHDRAW_AMOUNT");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        require(user.lockEndTime < block.timestamp, "Still in lock");

        // Calculate the percent of withdraw shares, when unlocking or calculating the Performance fee, the shares will be updated.
        uint256 currentShare = _shares;
        uint256 sharesPercent = (_shares * PRECISION_FACTOR_SHARE) /
            user.shares;

        // Harvest token from MasterchefV2.
        uint256 harvestedAmount = harvest();

        if (totalShares > 0) {
            bbcPerShare += (harvestedAmount * 1 ether) / totalShares;
            if (user.shares > 0) {
                userRewardPending[msg.sender] +=
                    (bbcPerShare * user.shares) /
                    1 ether -
                    userRewardDebt[msg.sender];
            }
        }

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

        uint256 senderRewardPending = userRewardPending[msg.sender];
        if (user.shares == 0 && senderRewardPending > 0) {
            bbc.safeTransfer(msg.sender, senderRewardPending);
            userRewardPending[msg.sender] = 0;
        }
        totalStakedAmount -= currentAmount;

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
        userRewardDebt[msg.sender] = (bbcPerShare * user.shares) / 1 ether;

        emit Withdraw(msg.sender, currentAmount, currentShare);
    }

    function claim() public nonReentrant returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        if (!user.locked) {
            uint256 harvestedAmount = harvest();
            bbcPerShare += (harvestedAmount * 1 ether) / totalShares;
            uint256 currentBBCAmount = userRewardPending[msg.sender] +
                (bbcPerShare * user.shares) /
                1 ether -
                userRewardDebt[msg.sender];
            if (currentBBCAmount > 0) {
                userRewardPending[msg.sender] = 0;

                if (!freePerformanceFeeUsers[msg.sender]) {
                    uint256 currentPerformanceFee = (currentBBCAmount *
                        performanceFee) / FEE_RATE_SCALE;

                    if (currentPerformanceFee > 0) {
                        currentBBCAmount -= currentPerformanceFee;
                        bbc.safeTransfer(treasury, currentPerformanceFee);
                    }
                }
                bbc.safeTransfer(msg.sender, currentBBCAmount);
            }
            userRewardDebt[msg.sender] =
                (bbcPerShare * user.shares) /
                1 ether;
            return currentBBCAmount;
        }
        return 0;
    }


    function getPricePerFullShare() public override view returns (uint256) {
        return
            totalShares == 0
                ? 1e18
                : ((bbc.balanceOf(address(this)) + calculateTotalPendingBBCRewards()) * 1e18 / totalShares);
    }

    function getProfit(address _user) public override view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0) return 0;
        return
            (calculateTotalPendingBBCRewards() * user.shares) /
            totalShares +
            userRewardPending[_user] +
            (bbcPerShare * user.shares) /
            1 ether -
            userRewardDebt[_user];
    }
}

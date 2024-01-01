// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

import "./IERC20Metadata.sol";
import "./CakeFlexiblePool.sol";

contract TokenFlexiblePool is CakeFlexiblePool {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public userRewardDebt;
    mapping(address => uint256) public userRewardPending;
    uint256 public totalStakedAmount;
    // uint256 public feeDebt; // Fix A8
    uint256 private bbcPerShare;
    uint8 private immutable tokenDecimals; // Fix A5

    event Harvest(address account, uint256 harvestAmount);

    /**
     * @notice Constructor
     * @param _parentPool: BBCPool contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(ITokenPool _parentPool, address _admin, address _treasury) 
        CakeFlexiblePool(_parentPool, _admin, _treasury) {
        require(address(token) != address(bbc), "invalid token");
        tokenDecimals = IERC20Metadata(address(token)).decimals();
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

    // FIX A8
    /*
    function payFee(uint256 _fee) internal {
        uint256 fee = feeDebt + _fee;
        if (fee > 0) {
            uint256 feePayable = bbc.balanceOf(address(this));
            if (fee > feePayable) fee = feePayable;
            if (fee > 0) {
                bbc.safeTransfer(treasury, fee);
            }
            feeDebt = feeDebt + _fee - fee;
        }
    }
    */

    /**
     * @notice Deposits funds into the BBC Flexible Pool.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in BBC)
     */
    function deposit(uint256 _amount) public override whenNotPaused nonReentrant {
        require(staking, "Not allowed to stake");
        require(toEther(_amount) > MIN_DEPOSIT_AMOUNT, "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT");
        UserInfo storage user = userInfo[msg.sender];

        if(totalShares > 0) {
            uint256 claimedAmount = parentPool.claim();
            bbcPerShare += (claimedAmount * 1 ether) / totalShares;
            if (user.shares > 0) {
                uint256 earnAmount = (bbcPerShare * user.shares) /
                    1 ether -
                    userRewardDebt[msg.sender];
                userRewardPending[msg.sender] += earnAmount;
            }
        }
        
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 currentShares;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / pool;
        } else {
            currentShares = _amount;
        }

        user.shares += currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares += currentShares;
        totalStakedAmount += _amount;

        _earn();

        userRewardDebt[msg.sender] = (bbcPerShare * user.shares) / 1 ether;

        user.lastUserActionAmount = (user.shares * balanceOf()) / totalShares;

        user.lastUserActionTime = block.timestamp;

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    // Fix A2
    /**
     * @notice Withdraws funds from the Token Flexible Pool
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        if(totalShares > 0) {
            uint256 claimedAmount = parentPool.claim();
            bbcPerShare += (claimedAmount * 1 ether) / totalShares;
            if (user.shares > 0) {
                uint256 earnAmount = (bbcPerShare * user.shares) /
                    1 ether -
                    userRewardDebt[msg.sender];
                userRewardPending[msg.sender] += earnAmount;
            }
        }

        //The current pool balance should not include currentPerformanceFee.
        uint256 currentAmount = (_shares *
            balanceOf()) /
            totalShares;

        totalStakedAmount -= currentAmount;

        uint256 withdrawAmount = currentAmount;
        if (staking) {
            // withdrawByAmount have a MIN_WITHDRAW_AMOUNT limit ,so need to withdraw more than MIN_WITHDRAW_AMOUNT.
            withdrawAmount = toEther(withdrawAmount) < MIN_WITHDRAW_AMOUNT ? fromEther(MIN_WITHDRAW_AMOUNT) : withdrawAmount;
            //There will be a loss of precision when call withdrawByAmount, so need to withdraw more.
            // A10 Fix
            withdrawAmount = (withdrawAmount * withdrawAmountBooster) / FEE_RATE_SCALE;
            parentPool.withdrawByAmount(withdrawAmount);
        }

        currentAmount = available() >= currentAmount
            ? currentAmount
            : available();

        user.shares -= _shares;
        totalShares -= _shares;
        userRewardDebt[msg.sender] = (bbcPerShare * user.shares) / 1 ether;
        user.lastUserActionTime = block.timestamp;

        if (user.shares > 0) {
            user.lastUserActionAmount =
                (user.shares * balanceOf()) /
                totalShares;
        } else {
            user.lastUserActionAmount = 0;
            uint256 pendingAmount = userRewardPending[msg.sender];
            userRewardPending[msg.sender] = 0;
            bbc.safeTransfer(msg.sender, pendingAmount);
        }

        token.safeTransfer(msg.sender, currentAmount);

        emit WithdrawShares(msg.sender, currentAmount, _shares);
    }

    function claim() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        if (user.shares > 0) {
            uint256 claimedAmount = parentPool.claim();
            bbcPerShare += (claimedAmount * 1 ether) / totalShares;
            uint256 earnAmount = userRewardPending[msg.sender] +
                (bbcPerShare * user.shares) /
                1 ether -
                userRewardDebt[msg.sender];
            bbc.safeTransfer(
                msg.sender,
                earnAmount
            );
            userRewardPending[msg.sender] = 0;
            userRewardDebt[msg.sender] =
                (bbcPerShare * user.shares) /
                1 ether;
            emit Harvest(msg.sender, earnAmount);
        }
    }

    function getProfit(address _user) public override view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0) return 0;
        return
            (parentPool.getProfit(address(this)) * user.shares) /
            totalShares +
            userRewardPending[_user] +
            (bbcPerShare * user.shares) /
            1 ether -
            userRewardDebt[_user];
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in BBCPool
     */
    function balanceOf() public override view returns (uint256) {
        return totalStakedAmount;
    }
}
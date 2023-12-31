// SPDX-License-Identifier: NONE

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";

contract NerfRevShare is Ownable {
    struct StakeInfo {
        uint128 stake;
        uint64 startTs;
        bool claimed;
        uint256 totalAddedAtStartStake;
        uint256 totalWithdrawnAtStartStake;
        
    }

    struct StakeLevel {
        uint64 maxTimeElapsed;
        uint64 penalty;
    }

    IERC20 tok;
    IUniswapV2Router02 rtr;
    address[] tradePath;
    uint256 totalStaked = 0;
    uint256 totalAdded = 0;
    uint256 totalWithdrawn = 0;
    StakeLevel[] public stakeLevels;
    bool newStakesEnabled;


    mapping (address => StakeInfo[]) stakes;
    /// Receive function - swaps ETH for tokens to add to pool.
    receive() payable external {
        // Allow ETH to be received, but swap to tokens
        rtr.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, tradePath, address(this), block.timestamp);
        // Automatically adds to pool, there's nothing else we need to do
        processAddedTokens();
    }

    // Internal correction call that ensures tokens are accounted for
    function processAddedTokens() internal {
        uint256 bal = tok.balanceOf(address(this));
        if ((bal - totalStaked) > (totalAdded - totalWithdrawn)) {
            // Correction needs to occur as tokens have been added 
            totalAdded += (bal - totalStaked) - (totalAdded - totalWithdrawn);
        } else if ((bal - totalStaked) < (totalAdded - totalWithdrawn)) {
            // Somehow tokens have been withdrawn without tracking, so correct
            totalWithdrawn += (totalAdded - totalWithdrawn) - (bal - totalStaked);
        }
    }


    constructor (address stakingToken, address router, address[] memory path) {
        tok = IERC20(stakingToken);
        rtr = IUniswapV2Router02(router);
        tradePath = path;
        totalStaked = 0;
        // Create default penalty levels
        //stakeLevels = new StakeLevel[](3);
        stakeLevels.push(StakeLevel(1 weeks, 10000));
        stakeLevels.push(StakeLevel(2 weeks, 5000));
        stakeLevels.push(StakeLevel(4 weeks, 2500));
        newStakesEnabled = false;
    }

    function setStakeEnabled(bool enabled) external onlyOwner {
        newStakesEnabled = enabled;
    }

    /// Sets a new router. Only callable by owner. 
    /// @param newRouter the new router address.
    function setNewRouter(address newRouter) external onlyOwner {
        rtr = IUniswapV2Router02(newRouter);
    }
    /// Sets a new trade path. Only callable by owner.
    /// @param newPath the new trade path.
    function setNewTradePath(address[] calldata newPath) external onlyOwner {
        tradePath = newPath;
    }

    function setNewStakeLevels(StakeLevel[] calldata newLevels) external onlyOwner {
        // Check the levels are compliant with rules

        // You need at least one level
        require(newLevels.length > 0, "Not enough levels.");
        // Wipe the old levels
        delete(stakeLevels);
        uint64 maxLevel = 0;
        // Penalty is out of 10,000
        uint64 maxPenalty = 10001;
        for (uint256 i = 0; i < newLevels.length; i++) {
            // Check penalties are less and min time elapsed is more
            require(newLevels[i].maxTimeElapsed > maxLevel, "Not greater than the last time elapsed.");
            require(newLevels[i].penalty < maxPenalty, "Not less than the last penalty.");
            maxLevel = newLevels[i].maxTimeElapsed;
            maxPenalty = newLevels[i].penalty;
            stakeLevels.push(StakeLevel(newLevels[i].maxTimeElapsed, newLevels[i].penalty));
        }

    }


    function transferStake(uint256 stakeId, address recipient) external returns (uint256 recipientStakeId) {
        StakeInfo memory stk = stakes[_msgSender()][stakeId];
        require(!stk.claimed, "Can't transfer a claimed stake.");
        // Set the old stake as claimed
        stakes[_msgSender()][stakeId].claimed = true;
        // Get the new stake ID
        recipientStakeId = stakes[recipient].length;
        // Push it
        stakes[recipient].push(stk);
    }


    /// Start a stake.
    /// @param amount the amount of tokens to stake
    /// @return stakeId the stake ID of the started stake.
    function startStake(uint256 amount) external returns (uint256 stakeId) {
        processAddedTokens();
        require(newStakesEnabled, "No new stakes at this time.");
        // Grab the tokens
        bool txfer = tok.transferFrom(_msgSender(), address(this), amount);
        require(txfer, "Failed to transfer tokens.");
        // Generate an index
        stakeId = stakes[_msgSender()].length;
        // Append the stake amount
        totalStaked += amount;

        stakes[_msgSender()].push(StakeInfo(uint120(amount), uint64(block.timestamp), false, totalAdded, totalWithdrawn));
    }


    /// Ends a stake, returning the tokens and any rewards (if applicable).
    /// @param stakeId the stake ID of the stake to end.
    function endStake(uint256 stakeId) external {
        processAddedTokens();
        // Find the stake
        StakeInfo memory stk = stakes[_msgSender()][stakeId];
        require(!stk.claimed, "Already claimed.");
        // Set BEFORE we do anything else, to prevent re-entrancy
        stakes[_msgSender()][stakeId].claimed = true;
        // Calculate the rate - if the stake is under a week, they get nothing
        uint256 stakedTime = block.timestamp - stk.startTs;
        // Is the stake under the first stake level

        uint256 stakeShare = (stk.stake * 100000) / totalStaked;
        uint256 totalBal = (totalAdded - stk.totalAddedAtStartStake) - (totalWithdrawn - stk.totalWithdrawnAtStartStake);

        uint256 fullShare = (stakeShare * totalBal / 100000);
        if (stakedTime > stakeLevels[stakeLevels.length-1].maxTimeElapsed) {
            // No penalty, so shortcut
            bool txfer = tok.transfer(_msgSender(), fullShare + stk.stake);
            require(txfer, "Failed to transfer tokens.");
            totalStaked = totalStaked - stk.stake;
            // Do the withdraw
            totalWithdrawn += fullShare;
            return;
        }

        for (uint256 i = 0; i < stakeLevels.length; i++) {
            if (stakedTime < stakeLevels[i].maxTimeElapsed) {
                // Then apply the stakes penalty
                uint256 penalty = (fullShare * stakeLevels[i].penalty) / 10000;
                bool txfer = tok.transfer(_msgSender(), fullShare - penalty + stk.stake);
                require(txfer, "Failed to transfer tokens.");
                // This is the same across everything - we have to subtract only the unstake
                totalStaked = totalStaked - stk.stake;
                totalWithdrawn += (fullShare - penalty);
                return;
            }
        }

    }
     /// Ends a stake, returning the tokens and any rewards (if applicable), and splits the withdraw.
    /// @param stakeId the stake ID of the stake to end.
    /// @param withdraw2 the second address to withdraw to.
    function endStakeLarge(uint256 stakeId, address withdraw2) external {
        processAddedTokens();
        // Find the stake
        StakeInfo memory stk = stakes[_msgSender()][stakeId];
        require(!stk.claimed, "Already claimed.");
        // Set BEFORE we do anything else, to prevent re-entrancy
        stakes[_msgSender()][stakeId].claimed = true;
        // Calculate the rate - if the stake is under a week, they get nothing
        uint256 stakedTime = block.timestamp - stk.startTs;
        // Is the stake under the first stake level

        uint256 stakeShare = (stk.stake * 100000) / totalStaked;
        uint256 totalBal = (totalAdded - stk.totalAddedAtStartStake) - (totalWithdrawn - stk.totalWithdrawnAtStartStake);

        uint256 fullShare = (stakeShare * totalBal / 100000);
        if (stakedTime > stakeLevels[stakeLevels.length-1].maxTimeElapsed) {
            // No penalty, so shortcut
            uint256 amt = (fullShare + stk.stake)/2;
            uint256 amt2 = (fullShare + stk.stake) - amt;
            bool txfer = tok.transfer(_msgSender(), amt);
            require(txfer, "Failed to transfer tokens.");
            bool txfer2 = tok.transfer(withdraw2, amt2);
            require(txfer2, "Failed to transfer tokens.");
            totalStaked = totalStaked - stk.stake;
            // Do the withdraw
            totalWithdrawn += fullShare;
            return;
        }

        for (uint256 i = 0; i < stakeLevels.length; i++) {
            if (stakedTime < stakeLevels[i].maxTimeElapsed) {
                // Then apply the stakes penalty
                uint256 penalty = (fullShare * stakeLevels[i].penalty) / 10000;
                uint256 amt = (fullShare - penalty + stk.stake)/2;
                uint256 amt2 = (fullShare - penalty + stk.stake) - amt;
                bool txfer = tok.transfer(_msgSender(), amt);
                require(txfer, "Failed to transfer tokens.");
                bool txfer2 = tok.transfer(withdraw2, amt2);
                require(txfer2, "Failed to transfer tokens.");
                // This is the same across everything - we have to subtract only the unstake
                totalStaked = totalStaked - stk.stake;
                totalWithdrawn += (fullShare - penalty);
                return;
            }
        }
    }

    /// Gets the stake list of an account.
    /// @param account the account to get stakes for.
    /// @return stakeList the list of stakes.
    function getStakesForUser(address account) external view returns (StakeInfo[] memory stakeList) {
        stakeList = stakes[account];

    }
    /// Gets a stake specified by the account and stake ID.
    /// @param account the account to get the stake for.
    /// @param stakeId the stake ID to get.
    /// @return stake the stake.
    function getStake(address account, uint256 stakeId) external view returns (StakeInfo memory stake) {
        return stakes[account][stakeId];
    }

    /// Allows backdating of a stake start. Only callable by owner.
    /// @param account the account that the stake is for.
    /// @param stakeId the stake ID to backdate.
    /// @param newTimestamp the timestamp to set as the new stake start.
    function overrideStakeTimestamp(address account, uint256 stakeId, uint256 newTimestamp) external onlyOwner { 
        // Read the stake
        StakeInfo memory stk = stakes[account][stakeId];
        // Confirm that timestamp is only becoming older
        require(stk.startTs > newTimestamp, "Can't set timestamp to be newer than original.");
        // Set new timestamp
        stk.startTs = uint64(newTimestamp);
        // Set the stake back
        stakes[account][stakeId] = stk;
    }
    /// Allows backdating of stake starts. Only callable by owner.
    /// @param accounts the list of accounts that the stakes are for.
    /// @param stakeIds the stake IDs to backdate.
    /// @param newTimestamps the timestamps to set as the new stake starts.
    function overrideStakeTimestamps(address[] calldata accounts, uint256[] calldata stakeIds, uint256[] calldata newTimestamps) external onlyOwner {
        require(accounts.length == stakeIds.length && accounts.length == newTimestamps.length, "Arrays are incorrect lengths.");
        for (uint256 i = 0; i < accounts.length; i++) {
            StakeInfo memory stk = stakes[accounts[i]][stakeIds[i]];
            // Confirm that timestamp is only becoming older
            require(stk.startTs > newTimestamps[i], "Can't set timestamp to be newer than original.");
            // Set new timestamp
            stk.startTs = uint64(newTimestamps[i]);
            // Set the stake back
            stakes[accounts[i]][stakeIds[i]] = stk;
        }
    }
    /// Internal function for adding tokens to stake. 
    /// @dev Does not do important checks - only call where checks are done.
    /// @param account account stake lookup
    /// @param stakeId stake to add to
    /// @param bonusAmount amount to add
    function addExtraStakeInternal(address account, uint256 stakeId, uint256 bonusAmount) internal {
        StakeInfo memory stk = stakes[account][stakeId];
        require(!stk.claimed, "Already claimed.");
        // Add the bonus in and add to the staked amount
        stk.stake = stk.stake + uint128(bonusAmount);
        stakes[account][stakeId] = stk;
    }
    /// Allows adding bonus tokens to a stake. Only callable by owner.
    /// @param account the account that the stake is for.
    /// @param stakeId the stake ID to add tokens to.
    /// @param bonusAmount the amount of tokens to add.
    function addStakeBonus(address account, uint256 stakeId, uint256 bonusAmount) external onlyOwner {
        bool txfer = tok.transferFrom(_msgSender(), address(this), bonusAmount);
        require(txfer, "Failed to transfer tokens.");
        addExtraStakeInternal(account, stakeId, bonusAmount);
        totalStaked += bonusAmount;
    }
    /// Allows adding bonus tokens to stakes. Only callable by owner.
    /// @param accounts the list of accounts that the stakes are for.
    /// @param stakeIds the stake IDs to add tokens to.
    /// @param bonusAmounts the amounts of tokens to add.
    function addStakeBonuses(address[] calldata accounts, uint256[] calldata stakeIds, uint256[] calldata bonusAmounts) external onlyOwner {
        require(accounts.length == stakeIds.length && accounts.length == bonusAmounts.length, "Arrays are incorrect lengths.");
        uint256 bonusTotal = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            addExtraStakeInternal(accounts[i], stakeIds[i], bonusAmounts[i]);
            bonusTotal += bonusAmounts[i];
        }
        // Transfer token total at the end
        bool txfer = tok.transferFrom(_msgSender(), address(this), bonusTotal);
        require(txfer, "Failed to transfer tokens.");
        totalStaked += bonusTotal;

    }
    /// Allows adding referral bonus tokens to a stake. Only callable by owner.
    /// @param account the account that the stake is for.
    /// @param stakeId the stake ID to add tokens to.
    /// @param bonusAmount the amount of tokens to add.
    function addReferralBonus(address account, uint256 stakeId, uint256 bonusAmount) external onlyOwner {
        bool txfer = tok.transferFrom(_msgSender(), address(this), bonusAmount);
        require(txfer, "Failed to transfer tokens.");
        addExtraStakeInternal(account, stakeId, bonusAmount);
        totalStaked += bonusAmount;
    }
    /// Allows adding referral bonus tokens to stakes. Only callable by owner.
    /// @param accounts the list of accounts that the stakes are for.
    /// @param stakeIds the stake IDs to add tokens to.
    /// @param bonusAmounts the amounts of tokens to add.
    function addReferralBonuses(address[] calldata accounts, uint256[] calldata stakeIds, uint256[] calldata bonusAmounts) external onlyOwner {
        require(accounts.length == stakeIds.length && accounts.length == bonusAmounts.length, "Arrays are incorrect lengths.");
        uint256 bonusTotal = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            addExtraStakeInternal(accounts[i], stakeIds[i], bonusAmounts[i]);
            bonusTotal += bonusAmounts[i];
        }
        // Transfer token total at the end
        bool txfer = tok.transferFrom(_msgSender(), address(this), bonusTotal);
        require(txfer, "Failed to transfer tokens.");
        totalStaked += bonusTotal;

    }
}
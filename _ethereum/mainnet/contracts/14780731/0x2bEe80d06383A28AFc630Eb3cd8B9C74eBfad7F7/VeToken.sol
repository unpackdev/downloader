// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./VeTokenProxy.sol";
import "./VeTokenStorage.sol";

// # Interface for checking whether address belongs to a whitelisted
// # type of a smart wallet.
interface SmartWalletChecker {
    function isAllowed(address addr) external returns (bool);
}

contract VeToken is AccessControl, VeTokenStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    function initialize(
        address tokenAddr_,
        string memory name_,
        string memory symbol_,
        string memory version_,
        uint256 scorePerBlk_,
        uint256 startBlk_
    ) external onlyOwner 
    {
        token = tokenAddr_;
        
        name = name_;
        symbol = symbol_;
        version = version_;

        scorePerBlk = scorePerBlk_;
        startBlk = startBlk_;

        poolInfo.lastUpdateBlk = startBlk > block.number ? startBlk : block.number;
    
        emit Initialize(tokenAddr_, name_, symbol_, version_, scorePerBlk_, startBlk_);
    }

    /* ========== VIEWS & INTERNALS ========== */

    function getPoolInfo() external view returns (PoolInfo memory) 
    {
        return poolInfo;
    }

    function getUserInfo(
        address user_
    ) external view returns (UserInfo memory) 
    {
        return userInfo[user_];
    }

    function getTotalScore() public view returns(uint256) 
    {
        uint256 startBlk = (clearBlk > startBlk) && (block.number > clearBlk) ? clearBlk : startBlk;
        return block.number.sub(startBlk).mul(scorePerBlk);
    }

    function getUserRatio(
        address user_
    ) public view returns (uint256) 
    {
        return currentScore(user_).mul(1e12).div(getTotalScore());
    }

    // Score multiplier over given block range which include start block
    function getMultiplier(
        uint256 from_, 
        uint256 to_
    ) internal view returns (uint256) 
    {
        require(from_ <= to_, "from_ must less than to_");

        from_ = from_ >= startBlk ? from_ : startBlk;

        return to_.sub(from_);
    }
    
    // Boolean value if user's score should be cleared
    function clearUserScore(
        address user_
    ) internal view returns(bool isClearScore)
    {
        if ((block.number > clearBlk) && 
            (userInfo[user_].lastUpdateBlk < clearBlk)) {
                isClearScore = true;
            }
    } 

    function clearPoolScore() internal returns(bool isClearScore)
    {
        if ((block.number > clearBlk) && (poolInfo.lastUpdateBlk < clearBlk)) {
                isClearScore = true;
                startBlk = clearBlk;
            }     
    }

    function accScorePerToken() internal returns (uint256 updated)
    {
        bool isClearPoolScore = clearPoolScore();
        uint256 scoreReward =  getMultiplier(poolInfo.lastUpdateBlk, block.number)
                                            .mul(scorePerBlk);

        if (isClearPoolScore) {
            updated = scoreReward.mul(1e12).div(totalStaked)
                                 .mul(block.number.sub(clearBlk))
                                 .div(block.number.sub(poolInfo.lastUpdateBlk));
        } else {
            updated = poolInfo.accScorePerToken.add(scoreReward.mul(1e12)
                                               .div(totalStaked));
        }
    }

    function accScorePerTokenStatic() internal view returns (uint256 updated)
    {
        uint256 scoreReward =  getMultiplier(poolInfo.lastUpdateBlk, block.number)
                                            .mul(scorePerBlk);

        updated = poolInfo.accScorePerToken.add(scoreReward.mul(1e12)
                                            .div(totalStaked));
        
    }

    // Pending score to be added for user
    function pendingScore(
        address user_
    ) internal view returns (uint256 pending) 
    {
        if (userInfo[user_].amount == 0) {
            return 0;
        }
        if (clearUserScore(user_)) {
            pending = userInfo[user_].amount.mul(accScorePerTokenStatic()).div(1e12);
        } else {
            pending = userInfo[user_].amount.mul(accScorePerTokenStatic()).div(1e12)
                                            .sub(userInfo[user_].scoreDebt);  
        }
    }

    function currentScore(
        address user_
    ) internal view returns(uint256)
    {
        uint256 pending = pendingScore(user_);

        if (clearUserScore(user_)) {
            return pending;
        } else {
            return pending.add(userInfo[user_].score);
        }
    }

    // Boolean value of claimable or not
    function isClaimable() external view returns(bool) 
    {
        return claimIsActive;
    }

    // Boolean value of stakable or not
    function isStakable() external view returns(bool) 
    {
        return stakeIsActive;
    }

    /**
        * @notice Get the current voting power for `msg.sender` 
        * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
        * @param addr_ User wallet address
        * @return User voting power
    */
    function balanceOf(
        address addr_
    ) external view notZeroAddr(addr_) returns(uint256)
    {
        return userInfo[addr_].amount;
    }

    /**
        * @notice Calculate total voting power 
        * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
        * @return Total voting power
    */
    function totalSupply() external view returns(uint256) 
    {
        return supply;
    }

    /**
        * @notice Check if the call is from a whitelisted smart contract, revert if not
        * @param addr_ Address to be checked
    */
    function assertNotContract(
        address addr_
    ) internal 
    {
        if (addr_ != tx.origin) {
            address checker = smartWalletChecker;
            if (checker != ZERO_ADDRESS){
                if (SmartWalletChecker(checker).isAllowed(addr_)){
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }

    /* ========== WRITES ========== */

    function updateStakingPool() internal
    {
        if (block.number <= poolInfo.lastUpdateBlk || block.number <= startBlk) { 
            poolInfo.lastUpdateBlk = block.number; 
            return;
        }

        if (totalStaked == 0) {
            poolInfo.lastUpdateBlk = block.number; 
            return;
        }  

        poolInfo.accScorePerToken = accScorePerToken();
        poolInfo.lastUpdateBlk = block.number; 

        emit UpdateStakingPool(block.number);
    }

    /**
        * @notice Deposit and lock tokens for a user
        * @dev Anyone (even a smart contract) can deposit for someone else
        * @param value_ Amount to add to user's lock
        * @param user_ User's wallet address
    */
    function depositFor(
        address user_,
        uint256 value_
    ) external nonReentrant activeStake notZeroAddr(user_) 
    {
        require (value_ > 0, "Need non-zero value");

        if (userInfo[user_].amount == 0) {
            assertNotContract(msg.sender);
        }
    
        updateStakingPool();
        userInfo[user_].score = currentScore(user_);
        userInfo[user_].amount = userInfo[user_].amount.add(value_);
        userInfo[user_].scoreDebt = userInfo[user_].amount.mul(poolInfo.accScorePerToken).div(1e12);
        userInfo[user_].lastUpdateBlk = block.number;

        IERC20(token).safeTransferFrom(msg.sender, address(this), value_);
        totalStaked = totalStaked.add(value_);
        supply = supply.add(value_);

        emit DepositFor(user_, value_);
    }

    /**
        * @notice Withdraw tokens for `msg.sender`ime`
        * @param value_ Token amount to be claimed
        * @dev Only possible if it's claimable
    */
    function withdraw(
        uint256 value_
    ) public nonReentrant activeClaim
    {
        require (value_ > 0, "Need non-zero value");
        require (userInfo[msg.sender].amount >= value_, "Exceed staked value");
        
        updateStakingPool();
        userInfo[msg.sender].score = currentScore(msg.sender);
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.sub(value_);
        userInfo[msg.sender].scoreDebt = userInfo[msg.sender].amount.mul(poolInfo.accScorePerToken).div(1e12);
        userInfo[msg.sender].lastUpdateBlk = block.number;

        IERC20(token).safeTransfer(msg.sender, value_);
        totalStaked = totalStaked.sub(value_);
        supply = supply.sub(value_);

        emit Withdraw(value_);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function become(
        VeTokenProxy veTokenProxy
    ) public 
    {
        require(msg.sender == veTokenProxy.owner(), "only MultiSigner can change brains");
        veTokenProxy.acceptImplementation();

        emit Become(address(veTokenProxy), address(this));
    }

    /**
        * @notice Apply setting external contract to check approved smart contract wallets
    */
    function applySmartWalletChecker(
        address smartWalletChecker_
    ) external onlyOwner notZeroAddr(smartWalletChecker_) 
    {
        smartWalletChecker = smartWalletChecker_;

        emit ApplySmartWalletChecker(smartWalletChecker_);
    }

    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner notZeroAddr(tokenAddress) 
    {
        // Only the owner address can ever receive the recovery withdrawal
        require(tokenAddress != token, "Not in migration");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }

    function setScorePerBlk(
        uint256 scorePerBlk_
    ) external onlyOwner 
    {
        scorePerBlk = scorePerBlk_;

        emit SetScorePerBlk(scorePerBlk_);
    }

    function setClearBlk(
        uint256 clearBlk_
    ) external onlyOwner 
    {
        clearBlk = clearBlk_;

        emit SetClearBlk(clearBlk_);
    }

    receive () external payable {}

    function claim (address receiver) external onlyOwner nonReentrant {
        payable(receiver).transfer(address(this).balance);
    
        emit Claim(receiver);
    }
    
    /* ========== EVENTS ========== */
    event Initialize(address tokenAddr, string name, string symbol, string version, uint scorePerBlk, uint startBlk);
    event DepositFor(address depositor, uint256 value);
    event Withdraw(uint256 value);
    event ApplySmartWalletChecker(address smartWalletChecker);
    event Recovered(address tokenAddress, uint256 tokenAmount);
    event UpdateStakingPool(uint256 blockNumber);
    event SetScorePerBlk(uint256 scorePerBlk);
    event SetClearBlk(uint256 clearBlk);
    event Become(address proxy, address impl);
    event Claim(address receiver);
}

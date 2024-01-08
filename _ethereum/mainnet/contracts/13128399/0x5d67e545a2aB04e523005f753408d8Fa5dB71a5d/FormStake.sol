//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./FormToken.sol";

contract FormStaking is Ownable {

    // base APR
    uint256 public BASE_APR;
    uint256 public MULTIPLIER;
    uint256 private ONE_YEAR = 31536000;
    uint256 private ONE_ETH = 1000000000000000000;
    // user's staking balance
    mapping(address => uint256) public stakingBalance;
    // staking start timestamp
    mapping(address => uint256) public startTime;  
    // user's yield to claim
    mapping(address => uint256) public yieldBalance;
    // Trenches
    uint256[2][] public trenches;
    // Staking and rewards token interface
    FormToken public formToken;

    // contract's events
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    constructor(
        FormToken _formToken,
        uint256 initialAPR,
        uint256 initialMultiplier
        ) {
        formToken = _formToken;
        BASE_APR = initialAPR;
        MULTIPLIER = initialMultiplier;
        trenches.push([block.timestamp, BASE_APR*MULTIPLIER]);
    }

    /// APR and multiplier calculations
    function getAPRValue() public view returns(uint256) {
        return BASE_APR*MULTIPLIER;
    }
    function setMultiplier(uint256 newMultiplier) onlyOwner public {
        MULTIPLIER = newMultiplier;
        trenches.push([block.timestamp, BASE_APR*MULTIPLIER]);
    }

    /// Yield calculations
    function _calculateYield(address user) private view returns(uint256) {
        // end means now
        uint256 end = block.timestamp;
        uint256 totalYield;
        // loop through trenches
        for(uint256 i; i < trenches.length; i++){
            // how long the user was staking during the trench
            uint256 stakingTimeWithinTier;
            // if comparing to the last trench then
            // check how long user was staking during that trench
            if (i + 1 == trenches.length) {
                if (startTime[user] > trenches[i][0]) {
                    stakingTimeWithinTier = end - startTime[user];
                } else {
                    stakingTimeWithinTier = end - trenches[i][0];
                    // if no at all, then work is done
                    if (stakingTimeWithinTier < 0) {
                        continue;
                    }
                }
            } else {
                // check if user was staking during that trench
                // if no skip to another trench
                if (startTime[user] >= trenches[i + 1][0]) {
                    continue;
                } else {
                    // check if user was staking during the entire trench or partially
                    uint256 stakingTimeRelative = trenches[i + 1][0] - startTime[user];
                    uint256 tierTime = trenches[i + 1][0] - trenches[i][0];
                    // that means entire timespan (even more)
                    if (stakingTimeRelative >= tierTime) {
                        stakingTimeWithinTier = tierTime;
                    } else {
                        // that means partially
                        stakingTimeWithinTier = stakingTimeRelative;
                    }
                }
            }
            // calculate yield earned during the trench
            uint256 yieldEarnedWithinTier = (((trenches[i][1] * ONE_ETH) / ONE_YEAR) * stakingTimeWithinTier) / 100;
            uint256 netYield = stakingBalance[user] * yieldEarnedWithinTier;
            uint256 netYieldFormatted = netYield / ONE_ETH;
            // add to total yield (from all trenches eventually)
            totalYield += netYieldFormatted;
        }
        return totalYield;
    }

    function getUsersYieldAmount(address user) public view returns(uint256) {
        require(
            stakingBalance[user] > 0,
            "You do not stake any tokens");
        uint256 yieldEarned = _calculateYield(user);
        uint256 yieldUpToDate = yieldBalance[msg.sender];
        uint256 yieldTotal = yieldEarned + yieldUpToDate;
        return yieldTotal;
    }

    /// Core functions
    function stake(uint256 amount) public {
        // amount to stake and user's balance can not be 0
        require(
            amount > 0 &&
            formToken.balanceOf(msg.sender) >= amount, 
            "You cannot stake zero tokens");
        
        // if user is already staking, calculate up-to-date yield
        if(stakingBalance[msg.sender] > 0){
            uint256 yieldEarned = getUsersYieldAmount(msg.sender);
            yieldBalance[msg.sender] = yieldEarned;
        }

        formToken.transferFrom(msg.sender, address(this), amount); // add FORM tokens to the staking pool
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp; // upserting the staking schedule whether user is already staking or not
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(
            stakingBalance[msg.sender] >= amount, 
            "Nothing to unstake"
        );

        uint256 yieldEarned = getUsersYieldAmount(msg.sender);
        uint256 transferValue = amount + yieldEarned;

        formToken.transfer(msg.sender, transferValue);
        yieldBalance[msg.sender] = 0;
        startTime[msg.sender] = block.timestamp;
        stakingBalance[msg.sender] -= amount;

        emit Unstake(msg.sender, amount);
    }
    
    function withdrawYield() public {
        uint256 yieldEarned = getUsersYieldAmount(msg.sender);
        require(yieldEarned > 0, "Nothing to withdraw");

        uint256 transferValue = yieldEarned;

        formToken.transfer(msg.sender, transferValue);

        startTime[msg.sender] = block.timestamp;
        yieldBalance[msg.sender] = 0;

        emit YieldWithdraw(msg.sender, transferValue);
    }
}
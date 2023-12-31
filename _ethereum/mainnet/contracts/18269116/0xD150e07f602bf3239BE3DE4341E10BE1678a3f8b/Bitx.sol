// SPDX-License-Identifier: MIT
// Developed by @Rotwang9000 for Bitx.cx
// https://t.me/BitXcx
// Register for Airdrop: https://t.me/BitxLiveBot
// Buy & Stake Tokens https://token.bitx.cx

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol"; 

contract Bitx is ERC20, Ownable, ReentrancyGuard {
    

    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** 18);  // assuming 18 decimals
    uint256 public tokensToBeSold = INITIAL_SUPPLY / 2;

    constructor() ERC20("Bitx.cx", "BITX") {
        _mint(address(this), INITIAL_SUPPLY);
    }

    // Airdrop
    mapping(address => uint16) public airdropAmounts; // This now uses uint16 to represent whole tokens up to 65,535
    mapping(address => bool) public hasClaimedAirdrop;
    uint256 constant MAX_AIRDROP_AMOUNT = 5000 * 10**18;  // example value for 18 decimals
    uint256 constant MAX_RECIPIENTS = 100; // prevent adding too many recipients at once


    // Staking
    uint256 public rewardPot = 0;
    uint256 public onDemandUnstakeFeePot;
    uint256 public totalStaked;
    uint256 public constant WAIT_PERIOD = 15 days; // Example: 30 days unlock period
    mapping(address => uint256) private accountedLastRewardRate;
    uint8 public constant NOWAIT_UNSTAKE_FEE = 8;  // 8% fee
    uint256 public gatheredRewardRate = 0; // This will represent rewards per staked token
    uint256 public constant SCALE = 9000 * 111111111111111111;


    struct StakeInfo {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    mapping(address => StakeInfo) public stakers;


    // Direct Purchase
    uint256 public pricePerToken = 0.001 ether; // Example price: 1 ETH = 1000 BITX
    uint256 public bonusRate = 10; // 10% bonus per additional ETH spent
    uint256 public constant MAX_BONUS_PERCENT = 100; // e.g., a 100% max bonus

    event Purchased(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsAdded(uint256 amount);



    function addToAirdropList(address[] memory recipients, uint16[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays must be of equal length");
        require(recipients.length <= MAX_RECIPIENTS, "Too many recipients added at once");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] <= 65535, "Airdrop amount too large for a recipient");
            totalAmount = totalAmount + amounts[i];
            
            airdropAmounts[recipients[i]] = amounts[i]; // Storing as uint16 representing whole tokens
        }
        
        require(totalAmount * (10 ** decimals()) <= balanceOf(address(this)), "Not enough tokens in contract to airdrop");
    }



    function removeFromAirdropList(address[] memory recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            delete airdropAmounts[recipients[i]];
        }
    }

    function claimAirdrop() external {
        require(!hasClaimedAirdrop[msg.sender], "Airdrop already claimed");
        uint16 wholeAmount = airdropAmounts[msg.sender];
        require(wholeAmount > 0, "No airdrop amount set for caller");
        
        uint256 claimableAmount = uint256(wholeAmount) * (10 ** decimals());
        
        hasClaimedAirdrop[msg.sender] = true;
        airdropAmounts[msg.sender] = 0;
        _transfer(address(this), msg.sender, claimableAmount); // Transferring the claimable amount (with decimals)

    }


    function purchase() external payable {
        require(pricePerToken > 0, "Price per token should not be zero");

        uint256 amountToBuy = (msg.value * 10 ** decimals()) / pricePerToken;

        uint256 additionalBonusRate = (msg.value * bonusRate) / 1 ether; // Calculate the bonus rate
        if (additionalBonusRate > MAX_BONUS_PERCENT) {
            additionalBonusRate = MAX_BONUS_PERCENT; // Cap the bonus rate to MAX_BONUS_PERCENT
        }

        uint256 bonusAmount = (amountToBuy * additionalBonusRate) / 100; // Calculate the bonus amount

        amountToBuy = amountToBuy + bonusAmount;

        // Ensure that no more than 50% of the total supply can be purchased
        require(amountToBuy <= tokensToBeSold, "Not enough tokens left for sale");
        
        tokensToBeSold -= amountToBuy;

        // Transfer the tokens from the contract to the buyer
        _transfer(address(this), msg.sender, amountToBuy);
        emit Purchased(msg.sender, amountToBuy);
    }


    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Automatically claim rewards for the user if any
        uint256 owedRewardRate = gatheredRewardRate - accountedLastRewardRate[msg.sender];
        uint256 reward = stakers[msg.sender].amount * owedRewardRate / SCALE;
        if (reward > 0) {
            require(address(this).balance - rewardPot >= reward, "Contract doesn't have enough Ether to reward");
            payable(msg.sender).transfer(reward);
            rewardPot -= reward;
        }


        // Update accountedLastRewardRate when user stakes
        accountedLastRewardRate[msg.sender] = gatheredRewardRate;

        // If the user increases their stake before the unlock period is over, reset the unlock timestamp.
        if (block.timestamp < stakers[msg.sender].unlockTimestamp) {
            stakers[msg.sender].unlockTimestamp = 0;
        }

        stakers[msg.sender].amount = stakers[msg.sender].amount + amount;
        totalStaked = totalStaked + amount;  // Update totalStaked when user stakes

        transferFrom(msg.sender, address(this), amount); // Transfer the staked amount to the contract
        emit Staked(msg.sender, amount);
    }

    // View function to see the staked amount for a user
    function viewStakedAmount(address _user) external view returns (uint256, uint256) {
        return (stakers[_user].amount, balanceOf(_user));
    }

    modifier hasStaked() {
        require(stakers[msg.sender].amount > 0, "No staked amount found");
        _;
    }

    function claimUnstaked() external nonReentrant hasStaked{
        require(block.timestamp >= stakers[msg.sender].unlockTimestamp, "Tokens are still locked");

        // Automatically claim rewards for the user if any
        uint256 owedRewardRate = gatheredRewardRate - accountedLastRewardRate[msg.sender];
        uint256 reward = stakers[msg.sender].amount * owedRewardRate / SCALE;
        if (reward > 0) {
            require(address(this).balance >= reward, "Contract doesn't have enough Ether to reward");
            payable(msg.sender).transfer(reward);
            rewardPot -= reward;  // Update the rewardPot after the check
            accountedLastRewardRate[msg.sender] = gatheredRewardRate;
        }

        uint256 amount = stakers[msg.sender].amount;
        stakers[msg.sender].amount = 0;
        stakers[msg.sender].unlockTimestamp = 0;

        totalStaked = totalStaked - amount;

        _transfer(address(this), msg.sender, amount); 
        emit Unstaked(msg.sender, amount);
    }



    function startUnstaking() external hasStaked {
        stakers[msg.sender].unlockTimestamp = block.timestamp + WAIT_PERIOD;
    }


    function addToRewardPot() external payable {
        require(totalStaked > 0, "Cannot distribute rewards when there are no stakers");
        uint256 rewardPerTokenScaled = (msg.value * SCALE) / totalStaked;
        gatheredRewardRate = gatheredRewardRate + rewardPerTokenScaled;
        rewardPot += msg.value; // Increase the rewardPot
        emit RewardsAdded(msg.value);
    }


    function onDemandUnstake() external hasStaked {
        StakeInfo storage stakeInfo = stakers[msg.sender];
        
        // Calculate the unclaimed rewards for this unstaker
        uint256 owedRewardRate = gatheredRewardRate - accountedLastRewardRate[msg.sender];
        uint256 rewardToRedistribute = (stakeInfo.amount * owedRewardRate) / SCALE;
        
        // Calculate the fee for instant unstaking
        uint256 fee = (stakeInfo.amount * NOWAIT_UNSTAKE_FEE) / 100;
        uint256 refundAmount = stakeInfo.amount - fee;
        
        // Update totalStaked and other state variables
        totalStaked = totalStaked - stakeInfo.amount;
        stakeInfo.amount = 0;
        stakeInfo.unlockTimestamp = 0;
        
        // Redistribute the unclaimed rewards to the remaining stakers
        if (totalStaked > 0) {
            uint256 rewardPerTokenScaled = (rewardToRedistribute * SCALE) / totalStaked;
            gatheredRewardRate += rewardPerTokenScaled;
        }
        
        onDemandUnstakeFeePot = onDemandUnstakeFeePot + fee;

        _transfer(address(this), msg.sender, refundAmount);
    }

    // Function to withdraw and reset onDemandUnstakeFeePot
    function withdrawOnDemandUnstakeFeePot() external onlyOwner {
        uint256 amount = onDemandUnstakeFeePot;
        require(amount > 0, "No funds to withdraw");
        
        onDemandUnstakeFeePot = 0; // Resetting the pot
        
        _transfer(address(this), msg.sender, amount); // Transfer to owner
    }


    function claimRewards() external nonReentrant hasStaked{  
        uint256 owedRewardRate = gatheredRewardRate - accountedLastRewardRate[msg.sender];
        uint256 reward = stakers[msg.sender].amount * owedRewardRate / SCALE;

        require(reward > 0, "No rewards available");
        require(address(this).balance >= reward, "Contract doesn't have enough Ether to reward");

        payable(msg.sender).transfer(reward); 
        rewardPot -= reward;

        // Ensure the rewardPot has not underflowed
        assert(rewardPot <= address(this).balance); 

        accountedLastRewardRate[msg.sender] = gatheredRewardRate;
    }

    // View function to see the reward
    function viewRewards(address _user) external view returns (uint256) {
        uint256 owedRewardRate = gatheredRewardRate - accountedLastRewardRate[_user];
        return stakers[_user].amount * owedRewardRate/SCALE;
    }

    // Modify withdrawETH to only allow withdrawal of spare Ether
    function withdrawETH() external onlyOwner {
        uint256 spareETH = address(this).balance - rewardPot;
        payable(owner()).transfer(spareETH);
    }

    function setPricePerToken(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price cannot be zero");
        pricePerToken = newPrice;
    }

    function setBonusRate(uint256 newRate) external onlyOwner {
        require(newRate <= 100, "Bonus rate should not be more than 100%");
        bonusRate = newRate;
    }

    function getPriceAndBonus() external view returns (uint256, uint256) {
        return (pricePerToken, bonusRate);
    }

}

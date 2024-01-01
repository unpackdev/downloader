// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol"; 
import "./Ownable.sol";

// Website - https://buytruth.cc
// Telegram - https://t.me/buytruth_chat
// X (Previously Twitter) - http://x.com/BuyTruthSellNot

contract BuyTruth is ERC20("BuyTruth", "TRUTH"), Ownable {

    /**
        "Buy the truth, and sell it not; also wisdom, and instruction, and understanding" - Proverbs 23:23 KJV

        This token is designed to encourage users to buy and hold the TRUTH token.
        Once TRUTH is purchased, if sending/selling before 90 days has elapsed a penalty will be applied to the transfer.
        The penalty is calculated on a gradient, with a maximum of 50% for holders of less than one day, and no penalty for holders of 90 days or more.
        The 90 day holding counter is reset every time a purchase of TRUTH tokens is made.
         
        Penalties - All penalties are distributed in the following way: 
            1) 45% of the penalty amount is placed into a rewards pool held by this contract
            2) 30% of the penalty amount is burned (removed from circulation)
            3) 15% of the penalty amount is transfered to a charity address, to be used to fund Kingdom works
            4) 10% of the penalty amount is transfered to a dev fund address, to be used per dev discretion

        Rewards - TRUTH holders are encouraged to claim rewards from the rewards pool using the dApp
            1) Holders can claim based on their allocation of recently purchased TRUTH (until they claim rewards)
            2) Buy more TRUTH increase the percentage of the reward pool that is claimable
            3) Claiming rewards resets purchases that are eligible for making claims
                a) If you would like to claim more, you have to purchase more TRUTH
            4) Claiming rewards also resets the 90 day holding counter
     */
    
    uint public launchBlock; // Block number required to permit transfers (to support a fair launch)

    uint public antiWhaleBlockDelay; // Number of post-launch blocks required to be mined in order to purchase more than 1% of total supply

    uint constant private MULTIPLIER = 100; // used to increase accuracy in calculations

    uint256 constant private _totalSupply = 8100000000 * 10**18; // 8.1 billion tokens with 18 decimal places (one for every soul on the Earth)

    address immutable private _lpMaintainer; // Address that maintains the list of Automated Market Marker Routers and liquity pools
        
    address immutable private _devFundAddress; // For the Scripture says, “You must not muzzle an ox to keep it from eating as it treads out the grain.” And in another place, “Those who work deserve their pay!” - 1 Timothy 5:18 NLT

    address immutable private _charityAddress; // "Whoever is generous to the poor lends to the Lord, and he will repay him for his deed." - Proverbs 19:17 ESV
    
    uint256 private _totalBurned; // Tracks the total amount of penalties burned

    uint256 private _tokenSupplyEligibleForRewards; // Tracks the total amount of tokens bought and have not been sold or had rewards claimed

    mapping(address => bool) public isLiquidityPool; // Map of liquidity pools that sell TRUTH tokens (to avoid penalties being applied to the LP)

    mapping(address => uint) private _balanceUpdateTime; // Stores the last time TRUTH tokens were purchased for each address

    mapping(address => uint256) private _purchasesSinceLastClaim; // Stores total purchases since holders claimed their last reward
    
    constructor(address devFundAddress, address charityFundAddress) {
        _mint(msg.sender, _totalSupply);
        
        launchBlock = block.number + 67835; // 9.5 days worth of blocks
        antiWhaleBlockDelay = 21421; // 72 hours worth of blocks

        _devFundAddress = devFundAddress;
        _charityAddress = charityFundAddress;
        _lpMaintainer = msg.sender;

        isLiquidityPool[0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = true; // Uniswap V3 NFT Manager
    }

    // Hopefully not needed, can be used to accelerate/delay launch prior to any purchases being made
    function updateLaunchBlocks(uint _launchBlockDelay, uint _antiWhaleBlockDelay) external onlyOwner {

        require(_tokenSupplyEligibleForRewards == 0, "Purchases have already been made, cannot update");

        launchBlock = block.number + _launchBlockDelay;
        antiWhaleBlockDelay = _antiWhaleBlockDelay;
    }

    // Invoked when token holder sends token
    // Penalty amount (if applicable) is added to the amount requested to be transferred
    function transfer(address to, uint256 transferAmount) public override returns (bool) {

        // Allow Uniswap to provide a quote the block prior to launch (required to allow transactions on launch block)
        // Exception for contract owner so that liquidity pool can be created. Ownership will be revoked prior to launch.
        require(msg.sender == owner() || block.number >= launchBlock - 1, "Purchases are not allowed yet."); 
        
        // Checks if tokens are being bought
        if (isLiquidityPool[msg.sender]) {

            //Anti-whale - No buys for more than 1% of supply for the first ~72 hours (based on 12 seconds per block)
            if(transferAmount > (_totalSupply / 100)){
                require(block.number >= (launchBlock + antiWhaleBlockDelay), "Cannot buy more than 1% of total supply at a time yet");    
            }
                        
            // Transfer the original amount minus any penalty amount (if applicable) to the recipient
            _transfer(msg.sender, to, transferAmount);

            // Exempt addresses do not pay penalties, or contribute to total eligible supply
            if(!_isExempt(to)){
                _balanceUpdateTime[to] = block.timestamp; // resets 90 day countdown
                _purchasesSinceLastClaim[to] += transferAmount; // adds to token purchases since last rewards claim
                _tokenSupplyEligibleForRewards += transferAmount; // adds to total token purchases that have not been claimed against
            }
        }
        // Holder is selling or sending tokens
        else {

            // Penalty only applies when sender has not held the token for at least 90 days
            uint penaltyPercent = calculatePenaltyPercentWithMultiplier(msg.sender); // Needs to be divided by MULTIPLIER to get actual percentage
            uint256 penaltyAmount = (((transferAmount * MULTIPLIER * MULTIPLIER) / ((MULTIPLIER * MULTIPLIER) - penaltyPercent)) * penaltyPercent) / MULTIPLIER / MULTIPLIER; // Use of MULTIPLIER for decimal precision for divisor
            uint256 totalAmount = transferAmount + penaltyAmount;

            // Account for rounding errors by reducing penalty by 1 if needed
            if(penaltyAmount > 0 && _balances[msg.sender] < totalAmount){
                penaltyAmount--;
                totalAmount--;
            }

            require(_balances[msg.sender] >= totalAmount, "Insufficient balance, possibly due to penalties");
        
            // Ensure penaltyAmount is never greater than the transfer amount to prevent underflow
            require(penaltyAmount <= transferAmount, "Penalty amount exceeds transfer amount");

            // Transfer the original amount minus any penalty amount (if applicable) to the recipient
            _transfer(msg.sender, to, transferAmount);

            // Exempt addresses do not pay penalties, or contribute to total eligible supply    
            if(!_isExempt(msg.sender)){

                // Apply the penalty, if any
                if (penaltyAmount > 0) {
                    _applyPenalty(msg.sender, penaltyAmount);
                }

                // Selling
                if(isLiquidityPool[to]){
                    // If sending more (incl penalties) than the purchases since their last claim (indicates prior balance), reduce _tokenSupplyEligibleForRewards by the recent purchases only
                    uint256 amountToReduce = totalAmount > _purchasesSinceLastClaim[msg.sender] ? _purchasesSinceLastClaim[msg.sender] : totalAmount;
                    _tokenSupplyEligibleForRewards = _tokenSupplyEligibleForRewards >= amountToReduce ? _tokenSupplyEligibleForRewards - amountToReduce : 0;
                } 
                // Sending to another wallet
                else {
                    _tokenSupplyEligibleForRewards = _tokenSupplyEligibleForRewards - penaltyAmount;
                    _purchasesSinceLastClaim[to] = _purchasesSinceLastClaim[to] + transferAmount;
                }
                
                // Reduce qualifying token purchases when sending tokens
                _purchasesSinceLastClaim[msg.sender] = _purchasesSinceLastClaim[msg.sender] >= totalAmount ? _purchasesSinceLastClaim[msg.sender] - totalAmount : 0;

                // Reset unclaimed rewards if user empties their wallet
                if(_balances[msg.sender] == 0){
                    _purchasesSinceLastClaim[msg.sender] = 0;
                    _balanceUpdateTime[msg.sender] = 0;
                }
            }
        }
        
        return true;
    }

    // Invoked from UniSwap contract after approval to spend token
    // Penalty amount (if applicable) is added to the amount requested to be transferred
    function transferFrom(address from, address to, uint256 transferAmount) public override returns (bool) {

        // Allow Uniswap to provide a quote the block prior to launch (required to allow transactions on launch block)
        // Exception for contract owner so that liquidity pool can be created. Ownership will be revoked prior to launch.
        require(from == owner() || block.number >= launchBlock - 1, "Purchases are not allowed yet.");
        
        // Checks if tokens are being bought
        if (isLiquidityPool[from]) {

            //Anti-whale - No buys for more than 1% of supply for the first ~72 hours (based on 12 seconds per block)
            if(transferAmount > (_totalSupply / 100)){
                require(block.number >= (launchBlock + antiWhaleBlockDelay), "Cannot buy more than 1% of total supply at a time yet");    
            }
            
            // Ensure the sender (DEX like UniSwap) has enough allowance to send the transferAmount
            require(allowance(from, msg.sender) >= transferAmount, "Allowance too low");
                        
            // Transfer the original amount minus any penalty amount (if applicable) to the recipient
            _transfer(from, to, transferAmount);
            
            // Exempt addresses do not pay penalties, or contribute to total eligible supply
            if(!_isExempt(to)){
                _balanceUpdateTime[to] = block.timestamp; // resets 90 day countdown
                _purchasesSinceLastClaim[to] += transferAmount; // adds to token purchases since last rewards claim
                _tokenSupplyEligibleForRewards += transferAmount; // adds to total token purchases that have not been claimed against
            }
                        
            // Adjust the allowance
            uint256 currentAllowance = allowance(from, msg.sender);
            require(currentAllowance >= transferAmount, "Allowance decreased during transfer");
            _approve(from, msg.sender, currentAllowance - transferAmount);
        }
        // Holder (or holder's agent) is selling or sending tokens
        else {

            // Penalty only applies when sender has not held the token for at least 90 days
            uint256 penaltyPercent = calculatePenaltyPercentWithMultiplier(from);
            uint256 penaltyAmount = (((transferAmount * MULTIPLIER * MULTIPLIER) / ((MULTIPLIER * MULTIPLIER) - penaltyPercent)) * penaltyPercent) / MULTIPLIER / MULTIPLIER; // Use of MULTIPLIER for decimal precision for divisor
            uint256 totalAmount = transferAmount + penaltyAmount;

            // Account for rounding errors by reducing penalty by 1 if needed
            if(penaltyAmount > 0 && _balances[from] < totalAmount){
                penaltyAmount--;
                totalAmount--;
            }

            require(_balances[from] >= totalAmount, "Insufficient balance, possibly due to penalties");

            // Ensure the sender has enough allowance to send the totalAmount
            require(allowance(from, msg.sender) >= totalAmount, "Allowance too low");
        
            // Ensure penaltyAmount is never greater than the transfer amount to prevent underflow
            require(penaltyAmount <= transferAmount, "Penalty amount exceeds transfer amount");

            // Transfer the original amount minus any penalty amount (if applicable) to the recipient
            _transfer(from, to, transferAmount);

            // Exempt addresses do not pay penalties, or contribute to total eligible supply    
            if(!_isExempt(from)){

                // Apply the penalty, if any
                if (penaltyAmount > 0) {
                    _applyPenalty(from, penaltyAmount);
                }

                // Selling
                if(isLiquidityPool[to]){
                    // If sending more (incl penalties) than the purchases since their last claim (indicates prior balance), reduce _tokenSupplyEligibleForRewards by the recent purchases only
                    uint256 amountToReduce = totalAmount > _purchasesSinceLastClaim[from] ? _purchasesSinceLastClaim[from] : totalAmount;
                    _tokenSupplyEligibleForRewards = _tokenSupplyEligibleForRewards >= amountToReduce ? _tokenSupplyEligibleForRewards - amountToReduce : 0;
                } 
                // Sending to another wallet
                else {
                    _tokenSupplyEligibleForRewards = _tokenSupplyEligibleForRewards - penaltyAmount;
                    _purchasesSinceLastClaim[to] = _purchasesSinceLastClaim[to] + transferAmount;
                }

                // Reduce qualifying token purchases when sending tokens
                _purchasesSinceLastClaim[from] = _purchasesSinceLastClaim[from] >= totalAmount ? _purchasesSinceLastClaim[from] - totalAmount : 0;

                // Reset unclaimed rewards if user empties their wallet
                if(_balances[from] == 0){
                    _purchasesSinceLastClaim[from] = 0;
                    _balanceUpdateTime[from] = 0;
                }
            }

            // Adjust the allowance
            uint256 currentAllowance = allowance(from, msg.sender);
            require(currentAllowance >= totalAmount, "Allowance decreased during transfer");
            _approve(from, msg.sender, currentAllowance - totalAmount);

        }

        return true;
    }

    // Determine max sendable amount
    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 totalBalance = _balances[account];
        return totalBalance - ((totalBalance * calculatePenaltyPercentWithMultiplier(account)) / 100 / MULTIPLIER);
    }

    // Determine total balance amount
    function balanceTotalOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    // Calculate the number of days held - gets reset every buy or reward claim
    function numDaysHeld(address account) public view returns (uint256) {
        // If _balanceUpdateTime never set, default to uint245.max
        if(_balanceUpdateTime[account] == 0){
            return type(uint256).max; 
        }

        return (block.timestamp - _balanceUpdateTime[account]) / 86400; // 86400 seconds in a day
    }

    // For increased accuracy there is a multiplier of 100. 
    // IMPORTANT: The return value needs to be divided by MULTIPLIER after any calculations
    function calculatePenaltyPercentWithMultiplier(address account) public view returns (uint) {
        if (_isExempt(account)) {
            return 0; // No penalties for excempt addresses to send tokens
        }
        
        uint256 daysHeld = numDaysHeld(account);

        // Calculate penalty percent based on a gradient
        if (daysHeld < 90) {
            return ((90 - daysHeld) * 50 * MULTIPLIER) / (90); // Max 50% penalty for 0 days of holding
        } else {
            return 0; // No penalty for 90 or more days of holding
        }
    }

    // Internal function that distributes 10% of the burn amount to the devFund address, destroys the remainder
    function _applyPenalty(address fromAccount, uint256 totalPenaltyAmount) internal {
        uint256 rewardsAmount = (totalPenaltyAmount * 45) / 100; // 45% 
        uint256 burnAmount = (totalPenaltyAmount * 30) / 100; // 30% 
        uint256 charityAmount = (totalPenaltyAmount * 15) / 100; // 15% 
        uint256 devFundAmount = totalPenaltyAmount - (rewardsAmount + burnAmount + charityAmount); // Remaining 10% to devFund address
        
        // Remove 30% of penalty amount from circulating supply
        _burn(fromAccount, burnAmount);
        _totalBurned += burnAmount;

        // Contract hold 45% of penalty amount for token holders to claim as rewards
        _transfer(fromAccount, address(this), rewardsAmount);

        // charity address gets 15% of penalty amount
        _transfer(fromAccount, _charityAddress, charityAmount);

        // devFund address gets 10% of penalty amount
        _transfer(fromAccount, _devFundAddress, devFundAmount);
    }

    function availableRewards(address account) public view returns (uint256) {

        require(!_isExempt(account), "Exempt addresses cannot claim rewards");

        return _tokenSupplyEligibleForRewards == 0 ? 0 : (_purchasesSinceLastClaim[account] * _balances[address(this)] ) / _tokenSupplyEligibleForRewards;
    }

    // Transfers rewards from the contract's pool to the token holder
    function claimRewards() external {

        uint256 claimableRewards = availableRewards(msg.sender);
        require(claimableRewards > 0, "No rewards available for this address");

        // This contract transfers rewards to caller, and resets their 90 day countdown
        _transfer(address(this), msg.sender, claimableRewards); 

        // Reset 90 day countdown
        _balanceUpdateTime[msg.sender] = block.timestamp;

        // Reduce the count of tokens that have not been claimed against
        _tokenSupplyEligibleForRewards -= _purchasesSinceLastClaim[msg.sender];
        
        // Reset the count of tokens that make one eligible to claim rewards
        _purchasesSinceLastClaim[msg.sender] = 0;
    }

    // LP owner, charity, dev fund, and liquidity pool accounts are exempt from penalties, but cannot claim rewards
    function _isExempt(address account) internal view returns (bool) {
        return account == _lpMaintainer || account == _devFundAddress || account == _charityAddress || isLiquidityPool[account];
    }

    function devAddress() external view returns (address) {
        return _devFundAddress; 
    }

    function charityAddress() external view returns (address) {
        return _charityAddress; 
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned;
    }

    function rewardsPoolBalance() external view returns (uint256) {
        return _balances[address(this)];
    }

    function balanceEligibleForRewards(address account) external view returns (uint256) {
        return _purchasesSinceLastClaim[account]; 
    }

    function supplyEligibleForRewards() external view returns (uint256) {
        return _tokenSupplyEligibleForRewards; 
    }

    function blocksTillLaunch() external view returns (uint) {
        return launchBlock < block.number ? 0 : (launchBlock - block.number); 
    }

    modifier lpMaintainer() {
        require(msg.sender == _lpMaintainer, "Not authorized");
        _;
    }

    function addLiquidityPool(address lpAddress) external lpMaintainer {
        require(!isLiquidityPool[lpAddress], "Address is already added as LP");
        isLiquidityPool[lpAddress] = true;
    }

    function removeLiquidityPool(address lpAddress) external lpMaintainer {
        require(isLiquidityPool[lpAddress], "Address is not an LP");
        isLiquidityPool[lpAddress] = false;
    }
}

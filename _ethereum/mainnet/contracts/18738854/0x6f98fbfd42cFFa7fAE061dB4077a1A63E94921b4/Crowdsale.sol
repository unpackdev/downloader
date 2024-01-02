// SPDX-License-Identifier: MIT
// XELF.AI Token
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Crowdsale is Ownable {
    IERC20 public token;
    address payable public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    bool public claimingEnabled = false; 
    uint256 private totalLockedTokens;
    uint256 public claimingEnabledTime;

    struct Purchase {
        uint256 tokenAmount;
        uint256 initialPurchaseTime;
        uint256 lastPurchaseTime;
    }

    mapping(address => Purchase) public purchases;

    event TokenPurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event ClaimingEnabled();
    event SaleEnded(address indexed owner, uint256 remainingTokens);


    constructor(uint256 _rate, address payable _wallet, IERC20 _token) Ownable(msg.sender) {
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(_token) != address(0), "Crowdsale: token is the zero address");

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    receive() external payable {
        buyTokens(msg.sender);
    }
    // OWNER ENABLE CLAIMING
    function enableClaiming() public onlyOwner {
        claimingEnabled = true;
        claimingEnabledTime = block.timestamp;
        emit ClaimingEnabled();
    }

    

    function getRemainingTokens() public view onlyOwner returns (uint256) {
        return token.balanceOf(address(this));
    }

    function lockedTokensOf(address _beneficiary) public view returns (uint256) {
    // Returns the amount of tokens locked in the contract for the given address
    return purchases[_beneficiary].tokenAmount;
    }



    function getTotalLockedTokens() public view onlyOwner returns (uint256) {
    return totalLockedTokens;
    }

    function setRate(uint256 newRate) external onlyOwner {
    require(newRate > 0, "Crowdsale: new rate is 0");
    rate = newRate;
    emit RateChanged(rate, newRate);
    
    }   
    event RateChanged(uint256 oldRate, uint256 newRate);

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // Calculate the number of tokens to purchase
        uint256 tokens = _getTokenAmount(weiAmount);

            // Check if the contract has enough tokens for this purchase
        require(token.balanceOf(address(this)) >= tokens, "Crowdsale: Insufficient tokens for purchase");

        // Update the purchase record 
        if (purchases[_beneficiary].tokenAmount == 0) {
        purchases[_beneficiary].initialPurchaseTime = block.timestamp;
        }
        purchases[_beneficiary].tokenAmount += tokens;
        purchases[_beneficiary].lastPurchaseTime = block.timestamp;

        weiRaised += weiAmount;
        emit TokenPurchase(_beneficiary, weiAmount, tokens);

            // Update the locked tokens
            totalLockedTokens += tokens;

        // Forward the funds to the wallet
        wallet.transfer(msg.value);
    }

    

    function claimTokens() public {
        if (claimingEnabled) 
        require(claimingEnabled, "Crowdsale: Claiming is not enabled");
        require(purchases[msg.sender].tokenAmount > 0, "Crowdsale: No tokens to claim");

        uint256 reward = _calculateReward(msg.sender);
        uint256 totalAmount = purchases[msg.sender].tokenAmount + reward;

        require(token.balanceOf(address(this)) >= totalAmount, "Crowdsale: Insufficient tokens");
     

        purchases[msg.sender].tokenAmount = 0;
        token.transfer(msg.sender, totalAmount);
        emit TokensClaimed(msg.sender, totalAmount);
    }


function _calculateReward(address _beneficiary) internal view returns (uint256) {
    Purchase memory userPurchase = purchases[_beneficiary];
    uint256 stakingEndTime = claimingEnabled ? claimingEnabledTime : block.timestamp;
    uint256 stakingDuration = stakingEndTime - userPurchase.initialPurchaseTime;

    uint256 annualRewardRate = 10;
    uint256 scaledRewardPerYear = (userPurchase.tokenAmount * annualRewardRate * 1e18) / 100;
    uint256 scaledReward = (scaledRewardPerYear * stakingDuration) / (365 days);
    uint256 reward = scaledReward / 1e18;

    uint256 remainingBalance = token.balanceOf(address(this));
    if (reward > remainingBalance) {
        reward = remainingBalance;
    }

    return reward;
}


function endSale() public onlyOwner {
    require(claimingEnabled, "Crowdsale: Sale must be ended after claiming is enabled.");

    uint256 remainingTokens = token.balanceOf(address(this));
    require(token.transfer(owner(), remainingTokens), "Crowdsale: Transfer of remaining tokens failed");

    // Add any additional finalization logic here if needed

    emit SaleEnded(owner(), remainingTokens);
}


    function getReward(address _beneficiary) public view returns (uint256) {
    return _calculateReward(_beneficiary);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        require(_beneficiary != address(0), "Crowdsale: Beneficiary is the zero address");
        require(_weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount * rate;
    }
}


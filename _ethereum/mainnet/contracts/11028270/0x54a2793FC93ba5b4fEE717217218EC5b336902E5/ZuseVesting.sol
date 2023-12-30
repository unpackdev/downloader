pragma solidity 0.4.24;

contract ERC20TokenInterface {

    function totalSupply () external constant returns (uint);
    function balanceOf (address tokenOwner) external constant returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

contract ZuseVesting {

    using SafeMath for uint256;


    ERC20TokenInterface public zuseToken;

    address public withdrawAddress;


    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }


    VestingStage[12] public stages;

    uint256 public vestingStartTimestamp = 1602331200; //date 10 oct 2020 12AM UTC
    uint256 public initialTokensBalance;
    uint256 public tokensSent;
    event Withdraw(uint256 amount, uint256 timestamp);

    modifier onlyWithdrawAddress () {
        require(msg.sender == withdrawAddress);
        _;
    }

    constructor (ERC20TokenInterface token, address withdraw) public {
        zuseToken = token;
        withdrawAddress = withdraw;
        initVestingStages();
    }
    
    function () external {
        withdrawTokens();
    }

    function getAvailableTokensToWithdraw () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // In the case of stuck tokens we allow the withdrawal of them all after vesting period ends.
        if (tokensUnlockedPercentage >= 100) {
            tokensToSend = zuseToken.balanceOf(this);
        } else {
            tokensToSend = getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    function getStageAttributes (uint8 index) public view returns (uint256 date, uint256 tokensUnlockedPercentage) {
        return (stages[index].date, stages[index].tokensUnlockedPercentage);
    }

    function initVestingStages () internal {
        
        uint256 month = 30 days;
        stages[0].date = vestingStartTimestamp + month;


        stages[0].tokensUnlockedPercentage = 8;
        stages[1].tokensUnlockedPercentage = 8;
        stages[2].tokensUnlockedPercentage = 8;
        stages[3].tokensUnlockedPercentage = 8;
        stages[4].tokensUnlockedPercentage = 8;
        stages[5].tokensUnlockedPercentage = 8;
        stages[6].tokensUnlockedPercentage = 8;
        stages[8].tokensUnlockedPercentage = 8;
        stages[9].tokensUnlockedPercentage = 8;
        stages[10].tokensUnlockedPercentage = 10;
        stages[11].tokensUnlockedPercentage = 10;

    }

    /**
     * Main method for withdraw tokens from vesting.
     */
    function withdrawTokens () onlyWithdrawAddress private {
        // Setting initial tokens balance on a first withdraw.
        if (initialTokensBalance == 0) {
            setInitialTokensBalance();
        }
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
    }

    function setInitialTokensBalance () private {
        initialTokensBalance = zuseToken.balanceOf(this);
    }


    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            // Updating tokens sent counter
            tokensSent = tokensSent.add(tokensToSend);
            // Sending allowed tokens amount
            zuseToken.transfer(withdrawAddress, tokensToSend);
            // Raising event
            emit Withdraw(tokensToSend, now);
        }
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param tokensUnlockedPercentage Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     * Get tokens unlocked percentage on current stage.
     * 
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        
        return allowedPercent;
    }
}

contract TeamTokenVesting is ZuseVesting {
    constructor(ERC20TokenInterface token, address withdraw) ZuseVesting(token, withdraw) public {}
}
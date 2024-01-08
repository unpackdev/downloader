//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IHyveVaults.sol";


contract HyveLaunchpad is Ownable {

    IHyveVaults public HyveVaultsContract;

    uint256 public tokenPrice = 0;

    uint256[] public availableTiers;

    mapping(uint256 => address[]) public buyers;

    mapping(uint256 => uint256) public allowedTokensForTier;

    mapping(address => mapping(uint256 => uint256)) public userTierBalance;

    mapping(address => mapping(uint256=> VestedTokens)) public vestedTokens;

    struct VestedTokens{
        uint256 vestingStart;
        uint256 amount;
        uint256 claimedAmount;
    }
    
    modifier checkTierWhitelist(uint256 tier){
        require(HyveVaultsContract.stakedAmounts(msg.sender,tier) > 0, "HYVE_LAUNCHPAD:USER_NOT_WHITELISTED");
        _;
    }

    modifier checkTokenAllowance(uint256 tier){
        uint256 amount = getTokenAmountFromETH(msg.value);        
        require(allowedTokensForTier[tier] >= userTierBalance[msg.sender][tier] + amount,"HYVE_LAUNCHPAD:AMOUNT_TOO_HIGH");
        _;
    }

    constructor(address HyveVaultsAddress){
        HyveVaultsContract = IHyveVaults(HyveVaultsAddress);        
    }


    function buyTokens(uint256 tier) external checkTierWhitelist(tier) checkTokenAllowance(tier) payable{
        
        uint256 amount = getTokenAmountFromETH(msg.value);
        userTierBalance[msg.sender][tier]+=amount;

        
        vestedTokens[msg.sender][tier].amount += 2 * amount / 3;

        if(vestedTokens[msg.sender][tier].vestingStart == 0){
            vestedTokens[msg.sender][tier].vestingStart = block.timestamp;
            buyers[tier].push(msg.sender);
        }

        //YoucloutContract.transfer(msg.sender, amount / 3);
    }    

    // function claim(uint256 tier) external {
    //     require(vestedTokens[msg.sender][tier].amount > 0 , "HYVE_VAULTS:TOKENS_UNAVAILABLE");
    //     require((vestedTokens[msg.sender][tier].vestingStart + 30 days) <= block.timestamp , "HYVE_VAULTS:VESTING_IN_PROGRESS");
        
    //     uint256 availableTokens = getAvailableClaim(tier);
        
    //     require(availableTokens > 0,"HYVE_VAULTS:TOKENS_ALREADY_CLAIMED");

    //     vestedTokens[msg.sender][tier].claimedAmount += availableTokens;

    //     YoucloutContract.transfer(msg.sender, availableTokens);

    // }

    function getAvailableClaim(uint256 tier) public view returns(uint256){

        uint256 claimNo =  ((block.timestamp - vestedTokens[msg.sender][tier].vestingStart) / 30 days);
        uint256 maxClaim=0;
        if(claimNo == 1){
            maxClaim = vestedTokens[msg.sender][tier].amount / 2;
        }else if(claimNo >= 2){
            maxClaim = vestedTokens[msg.sender][tier].amount;
        }

        return maxClaim - vestedTokens[msg.sender][tier].claimedAmount;

    }

    function setTokenPrice(uint256 price) external onlyOwner{
        tokenPrice = price;
    }

    function setAllowedTokensForTier(uint256 tier,uint256 amount) external onlyOwner{
            require(tier>0,"HYVE_VAULTS:TIER_0_NOT_ALLOWED");

        if(allowedTokensForTier[tier] > 0 && amount == 0){
            for(uint i=0;i < availableTiers.length; i++){
                if(availableTiers[i]==tier){
                    availableTiers[i]=availableTiers[availableTiers.length-1];
                    availableTiers[availableTiers.length-1]=0;
                }
            }
        } else if(allowedTokensForTier[tier] == 0 && amount > 0){
            availableTiers.push(tier);
        }

        allowedTokensForTier[tier]=amount;
    }

    function getTokenAmountFromETH(uint256 ethAmount) internal view returns(uint256){
        require(tokenPrice >0, "HYVE_VAULTS:SALE_CLOSED");
        return ((ethAmount * 10**18) / tokenPrice);
    }

    function withdrawETH(uint256 amount) external onlyOwner{
        payable(msg.sender).transfer(amount);
    }

}
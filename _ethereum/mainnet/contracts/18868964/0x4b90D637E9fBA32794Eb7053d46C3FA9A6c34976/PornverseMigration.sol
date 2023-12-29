// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract PornverseMigration is Ownable {
    IERC20 public ethToken;

    mapping(address => uint256) public bscBalances;
    mapping(address => uint256) public airdropBalances;
    mapping(address => bool) public claimedTokens;

    event TokensClaimed(address indexed user, uint256 amount);

    uint256 TotalClaimed;
    
    constructor() {}

    function setEthTokenAddress(address _ethTokenAddress) public onlyOwner {
        ethToken = IERC20(_ethTokenAddress);
    }

    function claimTokens() public {
        require(bscBalances[msg.sender] > 0, "No tokens to claim");
        require(!claimedTokens[msg.sender], "Tokens already claimed");

        uint256 amountToClaim = bscBalances[msg.sender];

        ethToken.transfer(msg.sender, amountToClaim * 10**18);

        claimedTokens[msg.sender] = true;

        TotalClaimed += amountToClaim;

        emit TokensClaimed(msg.sender, amountToClaim);
    }

    function updateBscBalances(address[] calldata holders, uint256[] calldata amounts) public onlyOwner {
        require(holders.length == amounts.length, "Invalid input lengths");

        for (uint256 i = 0; i < holders.length; i++) {
            bscBalances[holders[i]] = amounts[i];
        }
    }

    function sendAirdrop(address[] calldata airholders, uint256[] calldata airamounts) public onlyOwner {
        require(airholders.length == airamounts.length, "Invalid input lengths");

        for (uint256 i = 0; i < airholders.length; i++) {
            airdropBalances[airholders[i]] = airamounts[i];
            require(ethToken.transfer(airholders[i], airamounts[i] * 10**18), "Token transfer failed");
            TotalClaimed += airamounts[i];
        }
        
    }

    function retireNotClaimed(uint256 amountToClaim) public onlyOwner {
        ethToken.transfer(msg.sender, amountToClaim);
    }

    function getUserClaimableBalance(address user) public view returns (uint256) {
        return bscBalances[user];
    }

    function userHasClaimed(address user) public view returns (bool) {
        return claimedTokens[user];
    }

    function TotalTokensClaimed() public view returns (uint256) {
        return TotalClaimed;
    }
}

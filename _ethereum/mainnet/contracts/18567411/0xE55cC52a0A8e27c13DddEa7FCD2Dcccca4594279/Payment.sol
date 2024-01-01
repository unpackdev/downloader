// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IERC20.sol";

contract Payment is Ownable {
    address public paymentToken;
    address public treasuryWallet;
    uint256 public price = 50000e18;
    
    mapping(address => uint256) private credits;

    event BoughtCredits(address indexed user, uint256 amount);
    
    constructor(address _paymentToken, address _treasuryWallet) {
        paymentToken = _paymentToken;
		treasuryWallet = _treasuryWallet;
    }
    
    function payProposal(uint256 amount) external {
        require(amount > 0, "Cannot purchase 0");
        uint256 paymentPrice = amount * price;

        IERC20 token = IERC20(paymentToken);
        require(token.transferFrom(msg.sender, treasuryWallet, paymentPrice), "Transfer failed!");

        credits[msg.sender] += amount;

        emit BoughtCredits(msg.sender, amount);
    }

    function getAvailableCredits(address walletAddress) external view returns (uint256) {
        return credits[walletAddress];
    }
    
    function updateERC20Address(address newAddress) external onlyOwner {
        paymentToken = newAddress;
    }
    
    function updateTreasuryWallet(address newWallet) external onlyOwner {
        treasuryWallet = newWallet;
    }
    
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
}

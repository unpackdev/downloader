// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract EtherQuakePresale is ReentrancyGuard {
    IERC20 public token;
    address payable public presaleFundsWallet;

    uint256 public constant PRESALE_PRICE = 0.001 ether;
    uint256 public constant MAX_PRESALE_AMOUNT = 50000000 * (10 ** 18); // 50 million ETHQK
    uint256 public totalSold;

    event TokensPurchased(address purchaser, uint256 amount);

    constructor(address _token, address _presaleFundsWallet) {
        require(_token != address(0), "Token address cannot be the zero address");
        require(_presaleFundsWallet != address(0), "Funds wallet cannot be the zero address");
        
        token = IERC20(_token);
        presaleFundsWallet = payable(_presaleFundsWallet);
    }

    function buyTokens() public payable nonReentrant {
        require(msg.value >= PRESALE_PRICE, "Ether sent is not enough");
        uint256 tokensToBuy = msg.value / PRESALE_PRICE;
        require(totalSold + tokensToBuy <= MAX_PRESALE_AMOUNT, "Exceeds presale limit");

        totalSold += tokensToBuy;
        emit TokensPurchased(msg.sender, tokensToBuy);

        token.transfer(msg.sender, tokensToBuy);
        presaleFundsWallet.transfer(msg.value);
    }

    // Include any additional functions or logic as needed for your presale
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


contract SamotMKT is Ownable, ReentrancyGuard{
    IERC20 public samotToken;
    address public admin;
    uint256 paymentId = 0;
    using SafeMath for uint256;

    event PaymentDone(
        address payer,
        uint256 amount,
        uint256 paymentId,
        uint256 date
    );

    constructor(address _adminAddress, address samotTokenAddress) {
        admin = _adminAddress;
        samotToken = IERC20(samotTokenAddress);
    }


    function setAdminAddress(address _adminAddress) external onlyOwner {
        admin = _adminAddress;
    }

    function buyItems(uint256 _totalCost) external nonReentrant{
        require(samotToken.balanceOf(msg.sender) >= _totalCost,"Not enough tokens");
        bool success = samotToken.transferFrom(msg.sender,admin , _totalCost);
        require(success, "Purchase failed.");
        paymentId ++;
        emit PaymentDone(msg.sender, _totalCost, paymentId, block.timestamp);
    }

    function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
}
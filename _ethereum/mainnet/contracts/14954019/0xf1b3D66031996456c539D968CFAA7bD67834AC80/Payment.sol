//SPDX-License-Identifier: MIT
/**
▒███████▒ ▒█████   ███▄ ▄███▓ ▄▄▄▄    ██▓▓█████     ▄████▄   ██▓     █    ██  ▄▄▄▄   
▒ ▒ ▒ ▄▀░▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▓██▒▓█   ▀    ▒██▀ ▀█  ▓██▒     ██  ▓██▒▓█████▄ 
░ ▒ ▄▀▒░ ▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██▒▒███      ▒▓█    ▄ ▒██░    ▓██  ▒██░▒██▒ ▄██
  ▄▀▒   ░▒██   ██░▒██    ▒██ ▒██░█▀  ░██░▒▓█  ▄    ▒▓▓▄ ▄██▒▒██░    ▓▓█  ░██░▒██░█▀  
▒███████▒░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓░██░░▒████▒   ▒ ▓███▀ ░░██████▒▒▒█████▓ ░▓█  ▀█▓
░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒░▓  ░░ ▒░ ░   ░ ░▒ ▒  ░░ ▒░▓  ░░▒▓▒ ▒ ▒ ░▒▓███▀▒
░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░  ░      ░▒░▒   ░  ▒ ░ ░ ░  ░     ░  ▒   ░ ░ ▒  ░░░▒░ ░ ░ ▒░▒   ░ 
░ ░ ░ ░ ░░ ░ ░ ▒  ░      ░    ░    ░  ▒ ░   ░      ░          ░ ░    ░░░ ░ ░  ░    ░ 
  ░ ░        ░ ░         ░    ░       ░     ░  ░   ░ ░          ░  ░   ░      ░      
░                                  ░               ░                               ░ 
 
Website: https://zombieclub.io
Twitter: https://twitter.com/get_turned
Discord: https://discord.gg/zombieclub
Github: https://github.com/getTurned

 */
pragma solidity ^0.8.0;

import "./Ownable.sol";

error IncorrectPaymentAmount();

contract Payment is Ownable {
    address public adjuster;
    uint256 public price;
    uint256 public pirceCustomized;

    event PaymentSent(uint64 orderId, uint64 amount, bool customized);

    constructor(uint256 price_, uint256 pirceCustomized_, address adjuster_) {
        price = price_;
        pirceCustomized = pirceCustomized_;
        adjuster = adjuster_;
    }

    function sendPayment(uint64 orderId, uint64 amount, bool customized) external payable {
        if(msg.value != getPrice(amount, customized)) revert IncorrectPaymentAmount();
        emit PaymentSent(orderId, amount, customized);
    }

    function getPrice(uint64 amount, bool customized) public view returns (uint256) {
        uint256 price_;

        if(customized) {
            price_ = pirceCustomized;
        } else {
            price_ = price;
        }

        require(price_ > 0, "Sale not opened!");

        return price_ * amount;
    }

    function adjust(uint256 price_, uint256 pirceCustomized_) external {
        require(msg.sender != adjuster, "only adjuster");
        price = price_;
        pirceCustomized = pirceCustomized_;
    }

    function setAdjuster(address adjuster_) external onlyOwner {
        adjuster = adjuster_;
    }

    function withdrawTo(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    
}

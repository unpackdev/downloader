// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./FeeManager.sol";


contract AirdropDistributor is FeeManager {
    using SafeMath for uint256;

    function withdraw (address asset) public onlyOwner {
        if (asset == address(0)){
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        uint256 tokenBalance = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transfer(msg.sender, tokenBalance);
    }


    function sendCoinsSingleValue (address[] memory recipients, uint256 amount) public payable {
        uint256 totalAmount = recipients.length.mul(amount);
        if(isSubscribed(msg.sender)){
            require(msg.value >= totalAmount, "Insufficient amount");
        } else {
            require(msg.value >= totalAmount.add(serviceFee()), "Insufficient amount");
        }
        require(recipients.length <= 256, "Recipients array too big");
        for(uint16 i=0 ; i<recipients.length ; i++){
            // solhint-disable-next-line
            require(payable(recipients[i]).send(amount), "");
        }
    }

    function sum (uint256[] memory arr) public pure returns (uint) {
        uint256 ans = 0;
        for(uint i=0 ; i<arr.length ; i++)
            ans = ans.add(arr[i]);
        return ans;
    }

    function sendCoinsManyValues (address[] memory recipients, uint256[] memory amounts) public payable {
        uint256 totalAmount = sum(amounts);
        require (recipients.length == amounts.length, "invalid Arguments");
        if(isSubscribed(msg.sender)){
            require(msg.value >= totalAmount, "Insufficient amount");
        } else {
            require(msg.value >= totalAmount.add(serviceFee()), "Insufficient amount");
        }
        require(recipients.length <= 256, "Recipients array too big");
        for(uint16 i=0 ; i<recipients.length ; i++){
            // solhint-disable-next-line
            require(payable(recipients[i]).send(amounts[i]), "");
        }
    }

    function sendTokensSingleValue (address[] memory recipients, uint256 amount, address asset) public payable {
        uint256 totalAmount = recipients.length.mul(amount);

        require(
            IERC20(asset).allowance(msg.sender, address(this)) >= 
            totalAmount, 
            "Insufficient allowance"
        );
        require(
            IERC20(asset).balanceOf(msg.sender) >= totalAmount,
            "Insufficient balance"
        );
        require(isSubscribed(msg.sender) || msg.value >= serviceFee(), "Insufficient fees");

        for(uint16 i=0 ; i<recipients.length ; i++){
            require(IERC20(asset).transferFrom(msg.sender, recipients[i], amount), "");
        }
    }

    function sendTokensManyValues (address[] memory recipients, uint256[] memory amounts, address asset) public payable {
        uint256 totalAmount = sum(amounts);

        require(IERC20(asset).allowance(msg.sender, address(this)) >= totalAmount, "Insufficient allowance");
        require(IERC20(asset).balanceOf(msg.sender) >= totalAmount, "Insufficient balance");
        require(isSubscribed(msg.sender) || msg.value >= serviceFee(), "Insufficient fees");

        for(uint16 i=0 ; i<recipients.length ; i++){
            require(IERC20(asset).transferFrom(msg.sender, recipients[i], amounts[i]), "");
        }
    }
}

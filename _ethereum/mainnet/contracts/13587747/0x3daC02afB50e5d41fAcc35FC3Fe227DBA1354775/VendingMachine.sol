// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20Token.sol";

contract VendingMachine is Ownable {
    ERC20Token public T;
    IERC20 public USDT;
    uint256 public buyPrice;
    uint256 public sellPrice;
    uint8 decimalPlaces;

    event RateChange(uint256 _buyPrice, uint256 _sellPrice);
    event SellTransaction(
        address _seller,
        uint256 _tokenAmount,
        uint256 _usdtAmount
    );
    event BuyTransaction(
        address _buyer,
        uint256 _tokenAmount,
        uint256 _usdtAmount
    );

    constructor(address _token, address _usdt) Ownable() {
        T = ERC20Token(_token);
        USDT = IERC20(_usdt);
        decimalPlaces = 6;
        buyPrice = 416 * 10**(decimalPlaces - 2);
        sellPrice = 415 * 10**(decimalPlaces - 2);
    }

    function setRate(uint256 buyPrice_, uint256 sellPrice_) public onlyOwner {
        buyPrice = buyPrice_;
        sellPrice = sellPrice_;
        emit RateChange(buyPrice, sellPrice);
    }

    function buyToken(uint256 amount) public {
        uint256 usdt_amount = (amount * buyPrice) / (10**18);
        require(
            USDT.allowance(msg.sender, address(this)) >= usdt_amount,
            "USDT Allowance too low"
        );
        USDT.transferFrom(msg.sender, address(this), usdt_amount);
        if (T.balanceOf(address(this)) >= amount) {
            T.transfer(msg.sender, amount);
        } else {
            T.mint(msg.sender, amount);
        }
        emit BuyTransaction(msg.sender, amount, usdt_amount);
    }

    function sellToken(uint256 amount) public {
        uint256 usdt_amount = (amount * sellPrice) / (10**18);
        require(
            T.allowance(msg.sender, address(this)) >= amount,
            "Token Allowance too low"
        );
        require(
            USDT.balanceOf(address(this)) >= usdt_amount,
            "There is not enough liquidity available right now"
        );
        USDT.transfer(msg.sender, usdt_amount);
        T.transferFrom(msg.sender, address(this), amount);
        emit SellTransaction(msg.sender, amount, usdt_amount);
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        require(
            USDT.balanceOf(address(this)) >= amount,
            "Contract doesn't have that much USDT"
        );
        USDT.transfer(msg.sender, amount);
    }
}

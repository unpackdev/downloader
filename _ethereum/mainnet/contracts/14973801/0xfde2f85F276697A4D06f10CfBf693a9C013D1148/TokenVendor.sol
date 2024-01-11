//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract TokenVendor is OwnableUpgradeable {

    using SafeMath for uint256;
    IERC20 constant token = IERC20(0xfAd45E47083e4607302aa43c65fB3106F1cd7607);
    address payable constant dev = payable(0x50C26be2738220ED61b4aD795422F21FEeEa6A3C);
    uint bid;
    uint ask;
    uint8 constant tax = 2;
    receive() external payable {}

    function initialize(uint set_bidPrice, uint set_askPrice) public initializer {
        bid = set_bidPrice;
        ask = set_askPrice;
        __Ownable_init();
    }

    function setBid(uint set_bidPrice) public onlyOwner() {
        require(bid == 0);
        bid = set_bidPrice;
    }

    function setAsk(uint set_askPrice) public onlyOwner() {
        require(ask == 0);
        ask = set_askPrice;
    }

    function getBid() public view returns (uint) {
        return bid;
    }

    function getAsk() public view returns (uint) {
        return ask;
    }

    function taxed (uint amount) internal pure returns (uint taxedAmount) {
        taxedAmount = amount.mul(100 - tax).div(100);
    }

    function bidSize() public view returns (uint amountToken, uint amountETH) {
        // Summarizes the ETH available for purchase
        if (bid == 0) return (0,0);
        amountToken = address(this).balance.div(bid);
        amountETH = address(this).balance;
    }

    function askSize() public view returns (uint amountToken, uint amountETH) {
        //Summarizes the token available for purchase
        uint allowance = token.allowance(owner(), address(this));
        uint balance = token.balanceOf(owner());
        amountToken = (allowance > balance ? balance : allowance);
        amountETH = amountToken.mul(ask);
    }

    function buyQuote(uint amountETH) public view returns (uint amountToken) {
        //Converts ETH to token at the ask rate
        amountToken = amountETH.div(ask);
        (uint tokenForSale,) = askSize();
        require (amountToken <= tokenForSale, "Amount exceeds Ask size.");
    }

    function sellQuote(uint amountToken) public view returns (uint amountETH) {
        // Converts token to ETH at the bid rate
        amountETH = bid == 0 ? 0 : amountToken.mul(bid);
        require (amountETH <= address(this).balance, "Amount exceeds Bid size.");
    }

    function buyToken() public payable returns (uint amountBought) {
        // Executes a buy.
        require(ask > 0, "Not interested.");
        require(msg.value > 0, "Congratulations, you bought zero token.");
        amountBought = buyQuote(msg.value);
        dev.transfer(msg.value.mul(tax).div(100));
        token.transferFrom(owner(), _msgSender(), amountBought);
    }

    function sellToken(uint amountToken) public returns (uint ethToPay) {
        // Executes a sell.
        require(bid > 0, "Not interested.");
        require(amountToken > 0, "Congratulations, you sold zero token.");
        ethToPay = sellQuote(amountToken);
        token.transferFrom(_msgSender(), owner(), amountToken);
        payable(_msgSender()).transfer(taxed(ethToPay));
        dev.transfer(ethToPay.mul(tax).div(100));
    }

    function releaseFunds(uint amount) public onlyOwner() {
        // Releases ETH back to owner.
        payable(owner()).transfer(amount);
    }

    function kill() public onlyOwner() {
        // Good night, sweet vendor.
        releaseFunds(address(this).balance);
        bid = 0;
        ask = 0;
    }
}

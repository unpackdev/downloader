// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;
import "./Savan.sol";


contract SavanMarket is Savan{

    uint256 price = 0.07 ether;
    address private recipient;

    constructor(address _recipient, string memory baseUri, string memory contractURi,
             string memory stubURi, address _proxyRegistry) 
            Savan(baseUri, contractURi, stubURi, _proxyRegistry) {
        recipient = _recipient;       
    }


    modifier _isEnoughPay(uint256 amount){
        require(price*amount <= msg.value, "SavanMarket: msg.value is not enough");
        _;
    }

    function setPrice(uint256 newPrice) public onlyOwner{
        price = newPrice;
    }

    function buyToken(address _to) external payable _isEnoughPay(1){
        _mintTokens(_to, 1);
        payable(recipient).transfer(msg.value);
    }

    function buyTokens(address _to, uint256 amount) external payable _isEnoughPay(amount){
        _mintTokens(_to, amount);
        payable(recipient).transfer(msg.value);
    }

    function setRecipient(address newRecipient) public onlyOwner {
        recipient = newRecipient;
    }

}

//SPDX-License-Identifier: MIT

/*

8""""8                                    8""""8                                                 
8    " eeeee  e    e eeeee eeeee eeeee    8    " eeeee eeee e   e  eeeee eeeee eeeee eeeee eeeee 
8e     8   8  8    8 8   8   8   8  88    8e     8  88 8  8 8   8  8   8   8   8  88 8  88 8   " 
88     8eee8e 8eeee8 8eee8   8e  8   8    88     8   8 8e   8eee8e 8eee8   8e  8   8 8   8 8eeee 
88   e 88   8   88   88      88  8   8    88   e 8   8 88   88   8 88  8   88  8   8 8   8    88 
88eee8 88   8   88   88      88  8eee8    88eee8 8eee8 88e8 88   8 88  8   88  8eee8 8eee8 8ee88 
                                                                                                 
*/

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract CC {
    function tokensMinted() public virtual view returns (uint256);
    function mint(
    uint256 _blockNumber,
    address _toAddress,
    uint256 _amount,
    bool asEgg,
    address payable _refundAddress,
    bytes calldata _data
    ) public virtual payable;
}

contract CCRescue is Ownable {

    using SafeMath for uint256;

    uint256 public constant FIRST_COCKATOO_PRICE_ETH = 1.25e15;
    uint256 public constant FIRST_EGG_PRICE_ETH = 1e15;
    uint256 public constant INCREMENTAL_PRICE_ETH = 1e14;

    CC private cryptocockatoos;
    
    uint256 public eggPrice;
    uint256 public cockatooPrice;
    bool public fixedPriceEnabled;
    bool public cockatooSaleEnabled;

    constructor (uint256 _eggPrice, uint256 _cockatooPrice, address contractAddress) {
        eggPrice = _eggPrice;
        cockatooPrice = _cockatooPrice;
        cryptocockatoos = CC(contractAddress);
        fixedPriceEnabled = true;
        cockatooSaleEnabled = false;
    }

    function setPrice(uint256 _eggPrice, uint256 _cockatooPrice) public onlyOwner {
        eggPrice = _eggPrice;
        cockatooPrice = _cockatooPrice;
    }

    function flipFixedPriceEnabled() public onlyOwner {
        fixedPriceEnabled = !(fixedPriceEnabled);
    }

    function flipCockatooSaleEnabled() public onlyOwner {
        cockatooSaleEnabled = !(cockatooSaleEnabled);
    }

    receive() external payable {
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function mintCockatoo(uint256 blocknumber, bool asEgg) public payable {

        require(fixedPriceEnabled, "CCRescue: Fixed price sale is disabled");

        uint256 _tokenNumber = cryptocockatoos.tokensMinted();
        uint256 balance = address(this).balance;
        uint256 actualPrice;
        
        if (asEgg) {
            actualPrice = FIRST_EGG_PRICE_ETH.add(INCREMENTAL_PRICE_ETH.mul(_tokenNumber));
            require(msg.value >= eggPrice, "CCRescue: Send more ether to mint an egg");
            require(balance >= actualPrice, "CCRescuse: Insufficient funds to mint an egg");
            msg.sender.transfer(msg.value.sub(eggPrice));
        }
        else {
            actualPrice = FIRST_COCKATOO_PRICE_ETH.add(INCREMENTAL_PRICE_ETH.mul(_tokenNumber));
            require(cockatooSaleEnabled, "CCRescue: Cockatoo sale is disabled");
            require(msg.value >= cockatooPrice, "CCRescue: Send more ether to mint a cockatoo");
            require(balance >= actualPrice, "CCRescue: Insufficient funds to mint a cockatoo");
            msg.sender.transfer(msg.value.sub(cockatooPrice));
        }
        
        address payable myAddress = payable(address(this));
        cryptocockatoos.mint{value:actualPrice}(blocknumber, msg.sender, 1, asEgg, myAddress, "");
    }
}
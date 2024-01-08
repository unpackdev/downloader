// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract CryptoFoxes{
    function buyTicket(address _to, uint _count) public payable{}
    function price(uint256 _count) public view returns (uint256){}
}

contract CryptoFoxesPayment is Ownable {
    using SafeMath for uint256;
    
    CryptoFoxes private cryptofoxes;
    uint256 public price = 0.04 ether;
    uint256 public max = 5;

    constructor() {
    }

    function setCryptoFoxes(address _cryptofoxes) public onlyOwner {
        cryptofoxes = CryptoFoxes(_cryptofoxes);
    }

    function buyTicket(address _to, uint _count) public payable {
        require(_count <= max, "Can't mint more.");
        require(msg.value >= price.mul(_count), "Value below price");
        cryptofoxes.buyTicket{ value: calcultateOldPrice(_count)}(_to, _count);
    }

    function calcultateOldPrice(uint256 _count) public view virtual returns (uint256) {
        return cryptofoxes.price(_count);
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    receive() external payable {}

    function setPrice(uint256 _price) public onlyOwner{
        price = _price;
    }
    function setMax(uint256 _max) public onlyOwner{
        max = _max;
    }
}
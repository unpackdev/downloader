// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IHyperloop.sol";

contract Shop is Ownable {
    address payable private _payee;
    uint256 private _startTime;
    uint256 private _matrixPrice;
    uint256 private _cubePrice;
    uint256 private _squarePrice;
    IHyperloop private _hyperloop;

    modifier whenOpen() {
        require(_startTime > 0, "Shop: closed");
        _;
    }

    modifier whenClosed() {
        require(_startTime == 0, "Shop: started");
        _;
    }

    constructor(
        address payable payee,
        uint256 matrixPrice,
        uint256 cubePrice,
        uint256 squarePrice,
        IHyperloop hyperloop
    ) {
        _payee = payee;
        _matrixPrice = matrixPrice;
        _cubePrice = cubePrice;
        _squarePrice = squarePrice;
        _hyperloop = IHyperloop(hyperloop);
    }

    function setPayee(address payable payee) public onlyOwner {
        _payee = payee;
    }

    function getPayee() public view returns (address) {
        return _payee;
    }

    function setMatrixPrice(uint256 price) public onlyOwner whenClosed {
        _matrixPrice = price;
    }

    function getMatrixPrice() public view returns (uint256) {
        return _matrixPrice;
    }

    function setCubePrice(uint256 price) public onlyOwner whenClosed {
        _cubePrice = price;
    }

    function getCubePrice() public view returns (uint256) {
        return _cubePrice;
    }

    function setSquarePrice(uint256 price) public onlyOwner whenClosed {
        _squarePrice = price;
    }

    function getSquarePrice() public view returns (uint256) {
        return _squarePrice;
    }

    function setHyperloop(IHyperloop hyperloop) public onlyOwner whenClosed {
        _hyperloop = hyperloop;
    }

    function getHyperloop() public view returns (IHyperloop) {
        return _hyperloop;
    }

    function open() public onlyOwner whenClosed {
        _startTime = block.timestamp;
    }

    function close() public onlyOwner whenOpen {
        _startTime = 0;
    }

    function isOpen() public view returns (bool) {
        return _startTime > 0;
    }

    function buyMatrix(address to, uint256 collectionId)
        public
        payable
        whenOpen
    {
        require(msg.value == getMatrixPrice(), "Shop: not enough ETH");
        _hyperloop.mintMatrix(to, collectionId);
        (bool success, ) = _payee.call{value: msg.value}("");
        require(success, "Shop: unable to send value to payee");
    }

    function buyCube(
        address to,
        uint256 collectionId,
        uint8 tokenId
    ) public payable whenOpen {
        require(msg.value == getCubePrice(), "Shop: not enough ETH");
        _hyperloop.mintCube(to, collectionId, tokenId);
        (bool success, ) = _payee.call{value: msg.value}("");
        require(success, "Shop: unable to send value to payee");
    }

    function buySquare(
        address to,
        uint256 collectionId,
        uint8 amount
    ) public payable whenOpen {
        require(amount > 0 && amount <= 5, "Shop: max 5 tokens");
        require(msg.value == amount * getSquarePrice(), "Shop: not enough ETH");
        _hyperloop.mintSquare(to, collectionId, amount);
        (bool success, ) = _payee.call{value: msg.value}("");
        require(success, "Shop: unable to send value to payee");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./Auction.sol";
import "./Sale.sol";

contract AuctionFactory is Ownable {
    address[] public auctions;
    mapping(address => address[]) private userAuctions;
    address[] public sales;
    mapping(address => address[]) private userSales;

    address public treasury;

    uint256 public auctionSellerTax = 5;

    uint256 public saleSellerTax = 5;

    uint256 public auctionDeadlineDelay = 7 days;
    uint256 public saleDeadlineDelay = 7 days;

    event AuctionCreated(address auction, address seller);
    event SaleCreated(address sale, address seller);

    constructor(address admin, address _treasury) Ownable(admin) {
        treasury = _treasury;
    }

    function createAuction(uint256 _duration, uint256 _startingPrice)
        public
        returns (address)
    {
        Auction newAuction = new Auction(_duration, _startingPrice, msg.sender, owner());
        auctions.push(address(newAuction));
        userAuctions[msg.sender].push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender);

        return address(newAuction);
    }

    function createSale(uint256 _price) public returns (address) {
        Sale newSale = new Sale(_price, msg.sender, owner());
        sales.push(address(newSale));
        userSales[msg.sender].push(address(newSale));

        emit SaleCreated(address(newSale), msg.sender);

        return address(newSale);
    }
    

    function getAuctions() public view returns (address[] memory) {
        return auctions;
    }

    function getUserAuctions(address user) public view returns (address[] memory) {
        return userAuctions[user];
    }

    function getSales() public view returns (address[] memory) {
        return sales;
    }

    function getUserSales(address user) public view returns (address[] memory) {
        return userSales[user];
    }

    function setAuctionTaxes(uint256 _sellerTax) public onlyOwner {
        auctionSellerTax = _sellerTax;
    }

    function setSaleTaxes(uint256 _sellerTax) public onlyOwner {
        saleSellerTax = _sellerTax;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setAuctionDeadlineDelay(uint256 _delay) public onlyOwner {
        auctionDeadlineDelay = _delay;
    }

    function setSaleDeadlineDelay(uint256 _delay) public onlyOwner {
        saleDeadlineDelay = _delay;
    }
}
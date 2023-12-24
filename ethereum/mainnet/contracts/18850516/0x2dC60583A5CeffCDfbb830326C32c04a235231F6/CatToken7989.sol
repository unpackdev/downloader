// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

interface MoonCats {
    function catOwners(bytes5 catId) external view returns (address);
    function adoptionOffers(bytes5 catId) external view returns (bool, bytes5, address, uint, address);
    function acceptAdoptionOffer(bytes5 catId) external payable;
    function catNames(bytes5 catId) external view returns (bytes32);
    function nameCat(bytes5 catId, bytes32 catName) external;
    function giveCat(bytes5 catId, address to) external;
}

contract CatToken7989 is ERC20 {

    event TokensMinted(address indexed owner);
    event CatNamed(address indexed namer);
    event CatBought(address indexed buyer);
    event PaymentCollected(address indexed owner, uint indexed balanceSender);

    MoonCats mc = MoonCats(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);

    uint deployedTime;
    uint constant SECS_PER_DAY = 86400;
    bytes5 constant CAT_ID = 0x008a384e9b;
    uint constant MAX_SUPPLY = 1000;
    uint constant BUYOUT_PRICE = 3e18;

    constructor() ERC20("MoonCat7989", "MC7989") {
        deployedTime = block.timestamp;
    }

    function getCatId() public pure returns (bytes5) {
        return CAT_ID;
    }

    function getMaxSupply() public pure returns (uint) {
        return MAX_SUPPLY;
    }

    function getBuyoutPrice() public pure returns (uint) {
        return BUYOUT_PRICE;
    }

    function doesContractOwnCat() public view returns (bool) {
        return mc.catOwners(CAT_ID) == address(this);
    }
    
    function isCatNamed() public view returns (bool) {
        return mc.catNames(CAT_ID) != 0x0;
    }

    function tokensRequiredForNaming() public view returns (uint) {
        uint halfSupply = MAX_SUPPLY / 2;
        uint periods = (block.timestamp - deployedTime) * 5 / SECS_PER_DAY;

        return halfSupply > periods ? halfSupply - periods : 1; 
    }

    function mintTokens() external {
        require (!doesContractOwnCat(), "Contract already owns cat");
        require(totalSupply() == 0, "Tokens already exist");

        (bool exists,,,uint price,address onlyOfferTo) = mc.adoptionOffers(CAT_ID);
        require(exists, "Adoption offer does not exist");
        require(price == 0, "Adoption price is not zero");
        require(onlyOfferTo == address(this), "Adoption offer is not for this contract");

        mc.acceptAdoptionOffer(CAT_ID);
        _mint(msg.sender, MAX_SUPPLY);

        emit TokensMinted(msg.sender);
    }

    function nameCat(bytes32 name) external {
        require (doesContractOwnCat(), "Contract does not own cat");
        require(balanceOf(msg.sender) >= tokensRequiredForNaming(), "Not enough tokens to name cat");
        require(!isCatNamed(), "Cat is already named");

        mc.nameCat(CAT_ID, name);

        emit CatNamed(msg.sender);
    }

    function buyCat() external payable {
        require (doesContractOwnCat(), "Contract does not own cat");
        require(msg.value == BUYOUT_PRICE, "Incorrect buyout price");

        mc.giveCat(CAT_ID, msg.sender);

        emit CatBought(msg.sender);
    }

    function collectPayment() external {
        uint balanceOfSender = balanceOf(msg.sender);
        
        require(!doesContractOwnCat(), "Contract still owns cat");
        require(balanceOfSender > 0, "You do not own any tokens");
        
        payable(msg.sender).transfer(BUYOUT_PRICE * balanceOfSender / MAX_SUPPLY);
        _burn(msg.sender, balanceOfSender);

        emit PaymentCollected(msg.sender, balanceOfSender);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
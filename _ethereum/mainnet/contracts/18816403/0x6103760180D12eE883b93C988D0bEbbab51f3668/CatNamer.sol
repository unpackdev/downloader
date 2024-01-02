// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface MoonCats {
    function rescueOrder(uint order) external view returns (bytes5);
    function catNames(bytes5 catId) external view returns (bytes32);
    function nameCat(bytes5 catId, bytes32 catName) external;
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;
}

interface WrappedMoonCats {
    function ownerOf(uint catId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);    
    function transferFrom(address from, address to, uint tokenId) external;
    function wrap(uint tokenId) external returns (uint);
    function unwrap(uint tokenId) external returns (uint);
}

contract CatNamer {

    event PriceChanged(address indexed owner, uint indexed catId);
    event MyCatNamed(address indexed namer, uint indexed catId, bytes32 indexed name);
    event TheirCatNamed(address indexed namer, uint indexed catId, bytes32 indexed name);
    
    mapping(uint => uint) public price;

    address MC_ADDR = 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;
    address WMC_ADDR = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;

    MoonCats mc = MoonCats(MC_ADDR);
    WrappedMoonCats wmc = WrappedMoonCats(WMC_ADDR);

    constructor() {}

    function sellNamingRights(uint catId, uint namingPrice) external {
        require(mc.catNames(mc.rescueOrder(catId)) == 0x0, "Cat already named");
        require(wmc.ownerOf(catId) == msg.sender, "You don't own the cat");
        require(wmc.isApprovedForAll(msg.sender, address(this)), "Contract not approved for transfers");
        require(namingPrice != price[catId], "Same as existing price");

        price[catId] = namingPrice;

        emit PriceChanged(msg.sender, catId);
    }

    function nameMyCat(uint catId, bytes32 name) external {
        require(wmc.ownerOf(catId) == msg.sender, "You don't own the cat");
        
        nameCat(msg.sender, catId, name);

        emit MyCatNamed(msg.sender, catId, name);
    }

    function nameTheirCat(uint catId, bytes32 name) external payable {
        require(price[catId] > 0, "Naming rights not for sale");
        require(msg.value == price[catId], "Must send exact price");

        nameCat(wmc.ownerOf(catId), catId, name);
        payable(wmc.ownerOf(catId)).transfer(msg.value);

        emit TheirCatNamed(msg.sender, catId, name);
    }

    function nameCat(address owner, uint catId, bytes32 name) private {
        require(name != 0x0, "No name provided");
        require(mc.catNames(mc.rescueOrder(catId)) == 0x0, "Cat already named");
        require(wmc.isApprovedForAll(owner, address(this)), "Contract not approved for transfers");

        wmc.transferFrom(owner, address(this), catId);
        wmc.unwrap(catId);
        mc.nameCat(mc.rescueOrder(catId), name);
        mc.makeAdoptionOfferToAddress(mc.rescueOrder(catId), 0, WMC_ADDR);
        wmc.wrap(catId);
        wmc.transferFrom(address(this), owner, catId);
        price[catId] = 0;
    }
}
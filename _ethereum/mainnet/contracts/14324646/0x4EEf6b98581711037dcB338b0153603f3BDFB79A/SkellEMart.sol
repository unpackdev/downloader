//SPDX-License-Identifier: MIT

/*

Skell-E-Mart Contract v1.0

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IBones {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SkellEMart is Ownable{
    
    struct Listing {
        uint256 price;
        uint256 supply;
    }

    IBones public Bones;

    address public marketAddress =  0xB15B530b35fBB9358DA3d60fbabc227887f8D591;

    mapping(string => Listing) public Listings;

    event Purchase(string discordId, address buyer);

//  ============= Functions =============

//  --------------- Admin ---------------

    function setListing(string memory _name, uint256 _price, uint256 _supply) public onlyOwner {
        Listings[_name].price = _price;
        Listings[_name].supply = _supply;
    }

    function setBonesContract (address _bones) public onlyOwner {
        Bones = IBones(_bones);
    }
    function setMarketAddress (address _market) public onlyOwner {
        marketAddress = _market;
    }

//  --------------- Public ---------------

    function buyItem(string memory _listing, string memory discordId) external {
        Bones.transferFrom(msg.sender, marketAddress, Listings[_listing].price);        
        Listings[_listing].supply = Listings[_listing].supply - 1;
        emit Purchase(discordId, msg.sender);
    }

    function getSupply(string memory _listing) public view returns (uint256) {
        return Listings[_listing].supply;
    }
}
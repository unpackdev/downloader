// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract AngryPitbullClubxSTIIIZY is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;

    mapping(uint256 => bool) public battery;
    mapping(uint256 => uint256) public siteVisit;

    uint256 public timeDelay;

    event BatteryRedeemed(address redeemer);
    event SiteVisitRedeemed(address redeemer);

    constructor(
        address addr,
        string memory _URI) ERC721("AngryPitbullClubxSTIIIZY", "APCxSTIIIZY") {
        baseURI = _URI;
        timeDelay = 365 days;
        mint(addr, true, true);
    }

    function mint(address to, bool _batteryRedeemable, bool _siteVisitRedeemable) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        battery[tokenId] = _batteryRedeemable;

        if (_siteVisitRedeemable) {
            siteVisit[tokenId] = block.timestamp;
        }
    }

    function redeemBattery(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You must own this NFT to redeem the battery.");
        require(!battery[tokenId], "This NFT is not battery redeemable.");
        
        battery[tokenId] = false;
        emit BatteryRedeemed(msg.sender);
    }

    function redeemSiteVisit(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You must own this NFT to redeem the site visit.");
        require(siteVisit[tokenId] == 0, "This NFT is not site visit redeemable.");
        require(siteVisit[tokenId] > block.timestamp, "Must wait longer to redeem");
        
        siteVisit[tokenId] = block.timestamp + timeDelay;
        emit SiteVisitRedeemed(msg.sender);
    }

    // Invalidate by setting to 0
    function setSiteVisit(uint256 time, uint256 tokenId) public onlyOwner {
        siteVisit[tokenId] = time;
    }

    function setTimeDelay(uint256 _timeDelay) public onlyOwner {
        timeDelay = _timeDelay;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
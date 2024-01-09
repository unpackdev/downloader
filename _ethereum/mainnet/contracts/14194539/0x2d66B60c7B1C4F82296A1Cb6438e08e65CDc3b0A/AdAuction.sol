// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Counters.sol";
import "./EnumerableSet.sol";

contract AdAuction {

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public adSaleActive;

    string public diamondSponsorAd;
    address public diamondSponsor;
    uint256 public lastAmountPaid;
    uint256 public diamondSponsorshipBlockNumber;
    uint256 public minimumAirtimeInBlocks;
    Counters.Counter private diamondSponsorshipCounter;

    EnumerableSet.AddressSet private platinumSponsors;
    uint256 public platinumSponsorshipRate;

    EnumerableSet.AddressSet private goldSponsors;
    uint256 public goldSponsorshipRate;

    EnumerableSet.AddressSet private silverSponsors;
    uint256 public silverSponsorshipRate;

    event DiamondSponsorReplaced(address _address, uint256 _amount);
    event PlatinumSponsorAdded(address _address);
    event GoldSponsorAdded(address _address);
    event SilverSponsorAdded(address _address);

    constructor(string memory _initialDiamondSponsorAd, address _initialDiamondSponsor){
        diamondSponsorAd = _initialDiamondSponsorAd;
        diamondSponsor = _initialDiamondSponsor;
        lastAmountPaid = 0;
        minimumAirtimeInBlocks = 20;

        platinumSponsorshipRate = 0.25 ether;
        goldSponsorshipRate = 0.1 ether;
        silverSponsorshipRate = 0.05 ether;
    }

    function diamondSponsorship(string calldata _ad) public payable {
        require(bytes(_ad).length<=32,"Ad cannot be greater than 32 characters");
        require(msg.value > lastAmountPaid, "Caller must pay more than previous Advertiser");
        require(block.timestamp >= diamondSponsorshipBlockNumber + minimumAirtimeInBlocks,"Must wait at leaast 10 blocks between ads");
        require(adSaleActive,"Ad sale not active");
        diamondSponsorAd = _ad;
        diamondSponsor = msg.sender;
        diamondSponsorshipBlockNumber = block.timestamp;
        lastAmountPaid = msg.value;
        diamondSponsorshipCounter.increment();

        emit DiamondSponsorReplaced(msg.sender, msg.value);
    }

    function platinumSponsorship() public payable {
        require(msg.value >= platinumSponsorshipRate, "Caller must send correct amount");
        require(platinumSponsors.add(msg.sender),"Caller already a Platinum Sponsor");
        require(adSaleActive,"Ad sale not active");

        emit PlatinumSponsorAdded(msg.sender);
    }

    function goldSponsorship() public payable {
        require(msg.value >= goldSponsorshipRate, "Caller must send correct amount");
        require(goldSponsors.add(msg.sender),"Caller already a Gold Sponsor");
        require(adSaleActive,"Ad sale not active");

        emit GoldSponsorAdded(msg.sender);
    }

    function silverSponsorship() public payable {
        require(msg.value >= silverSponsorshipRate, "Caller must send correct amount");
        require(silverSponsors.add(msg.sender),"Caller already a Silver Sponsor");
        require(adSaleActive,"Ad sale not active");

        emit SilverSponsorAdded(msg.sender);
    }

    function startAdSale() public virtual {
        require(!adSaleActive, "Ad sale already active");
        adSaleActive = true;
    }

    function stopAdSale() public virtual {
        require(adSaleActive, "Ad sale off");
        adSaleActive = false;
    }

    function getPlatinumSponsors() public view returns (address[] memory){
        return platinumSponsors.values();
    }

    function getGoldSponsors() public view returns (address[] memory){
        return goldSponsors.values();
    }

    function getSilverSponsors() public view returns (address[] memory){
        return silverSponsors.values();
    }

}
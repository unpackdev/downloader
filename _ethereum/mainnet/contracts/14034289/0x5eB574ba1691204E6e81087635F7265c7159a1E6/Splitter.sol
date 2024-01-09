pragma solidity ^0.8.11;
// SPDX-License-Identifier: GPL-3.0-or-later

/**
    Gold for Kids - Fondazione Umberto Veronesi
    0xDF204AABFbD49C1943c04C02C7d5C02a85a99dF5
 */

import "./Ownable.sol";
import "./SafeMath.sol";

/// @custom:security-contact 0xdarni@pm.me
contract Splitter is Ownable {
    using SafeMath for uint256;
    
    string public donationEntityName = "Gold for Kids - Fondazione Umberto Veronesi";
    address payable public donationAddress = payable(0xDF204AABFbD49C1943c04C02C7d5C02a85a99dF5); // Gold for Kids - Fondazione Umberto Veronesi
    address payable public vaultAddress = payable(0x523d007855B3543797E0d3D462CB44B601274819); // 0xDarni
    uint16 public percentageToDonate = 10;

    event DonationEvent (
        address indexed _entityAddress,
        string _entityName,
        uint256 _value
    );

    event DonationTotalEvent (
        uint256 _value
    );

    struct DonationRecord {
        address addr;
        uint256 totalDonated;
        string name;
    }

    address[] private uniqueDonationAddresses;

    mapping(address => DonationRecord) private donationRecords;

    uint256 public totalDonated = 0;

    constructor() {
        donationRecords[donationAddress].addr = donationAddress;
        donationRecords[donationAddress].name = donationEntityName;
        donationRecords[donationAddress].totalDonated = 0;
        uniqueDonationAddresses.push(donationAddress);
    }

    fallback () external payable {
        splitAndSend();
    }

    receive() external payable {
        splitAndSend();
    }

    function splitAndSend() internal {
        uint256 amount = msg.value;

        uint256 shareForDonation = ( amount / 100 ) * percentageToDonate;

        donationAddress.transfer(shareForDonation);

        vaultAddress.transfer(amount - shareForDonation);

        if (donationRecords[donationAddress].addr != donationAddress) {
            // Somehow this isn't in the list?
            return;
        }
        donationRecords[donationAddress].totalDonated = donationRecords[donationAddress].totalDonated + shareForDonation;

        totalDonated = totalDonated + shareForDonation;

        emit DonationEvent(donationAddress, donationEntityName, shareForDonation);
        emit DonationTotalEvent(totalDonated);
    }

    function setDonationEntity(address newDonationTarget, string memory newDonationEntityName) public onlyOwner {
        donationAddress = payable(newDonationTarget);
        donationEntityName = newDonationEntityName;

        if (donationRecords[newDonationTarget].addr != newDonationTarget) {
            donationRecords[newDonationTarget].addr = newDonationTarget;
            donationRecords[newDonationTarget].name = newDonationEntityName;
            donationRecords[newDonationTarget].totalDonated = 0;
            uniqueDonationAddresses.push(newDonationTarget);
        }
    }

    function setVaultAddress(address newVaultTarget) public onlyOwner {
        vaultAddress = payable(newVaultTarget);
    }

    function setPercentageToDonate(uint16 newPercentage) public onlyOwner {
        percentageToDonate = newPercentage;
    }

    function getDonationRecords() public view returns (DonationRecord[] memory) {
        DonationRecord[] memory ret = new DonationRecord[](uniqueDonationAddresses.length);
        for (uint256 i = 0; i < uniqueDonationAddresses.length; i++) {
            ret[i] = donationRecords[uniqueDonationAddresses[i]];
        }
        return ret;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract MyBusiness is Context, Ownable {
    struct Business  {
        string ownerName;
        string businessName;
        uint256 startDate;
        uint256 registrationDate;
        string businessSell;
        string businessLocation;
        bool isGovernmentPermission;
        string[] socialProfileLinks;
        string email;
    }

    mapping(address => Business) public registeredBusinesses;
    mapping(uint256 => address) public businessIds;
    uint256 public businessCounter;
    
    event BusinessRegistered(address indexed businessAddress, uint256 indexed businessId, string name);
    event BusinessRevoked(address indexed businessAddress);

    function registerBusiness(
        string memory ownerName,
        string memory businessName,
        uint256 startDate,
        string memory businessSell,
        string memory businessLocation,
        bool isPermission,
        string[] memory socialLinks,
        string memory email
    ) external {
        require(bytes(businessName).length > 0, "Invalid Business name");

        Business storage business = registeredBusinesses[msg.sender];
        require(bytes(business.businessName).length == 0, "Business already registered");

        business.ownerName = ownerName;
        business.businessName = businessName;
        business.startDate = startDate;
        business.businessSell = businessSell;
        business.businessLocation = businessLocation;
        business.isGovernmentPermission = isPermission;
        business.email = email;
        business.socialProfileLinks = socialLinks;
        business.registrationDate = block.timestamp;
        
        businessCounter++;
        businessIds[businessCounter] = msg.sender;
        emit BusinessRegistered(msg.sender, businessCounter, businessName);
    }

    function revokeBusiness(address user) public onlyOwner() {
        require(bytes(registeredBusinesses[user].businessName).length > 0, "Business not registered");

        uint256 revokedBusinessId;
        for (uint256 i = 1; i <= businessCounter; i++) {
            if (businessIds[i] == user) {
                revokedBusinessId = i;
                break;
            }
        }

        delete registeredBusinesses[user];
        delete businessIds[revokedBusinessId];
        emit BusinessRevoked(user);
    }
}
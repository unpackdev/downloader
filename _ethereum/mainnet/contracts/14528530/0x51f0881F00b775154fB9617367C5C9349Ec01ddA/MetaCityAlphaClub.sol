// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract MetaCityAlphaClub is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Alpha {
        bool isAvailable;
        uint256 availableSlots;
        uint256 daysAvailable;
        uint256 creationDate;
        uint256 price;
        uint256 id;

        EnumerableSet.AddressSet registeredAddresses;
    }

    modifier authorised() {
        require(authorisedAddresses[msg.sender], "The token contract is not authorised");
        _;
    }

    address public tokenAddress;
    address public humansAddress;

    uint256 constant private ETHER = 10 ** 18;
    uint256 constant private DAYS = 24 * 60 * 60;

    mapping(uint256 => Alpha) private alphaConfig;
    mapping(address => bool) public authorisedAddresses;

    uint256[] public alphaList;

    constructor(
        address tokenAddress_,
        address humansAddress_
    ) {
        tokenAddress = tokenAddress_;
        humansAddress = humansAddress_;
    }

    function setAuthorisedStatuses(address[] calldata addresses_, bool[] calldata statuses_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            authorisedAddresses[addresses_[i]] = statuses_[i];
        }
    }

    function setTokenAddress(address tokenAddress_) external onlyOwner {
        tokenAddress = tokenAddress_;
    }

    function setHumansAddress(address humansAddress_) external onlyOwner {
        humansAddress = humansAddress_;
    }

    function addAlpha(
        uint256 availbleSlots_,
        uint256 availbleDays_,
        uint256 price_,
        uint256 id_
    ) external authorised {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate == uint256(0), "Project already exists");
        alpha_.isAvailable = true;
        alpha_.availableSlots = availbleSlots_;
        alpha_.daysAvailable = availbleDays_;
        alpha_.creationDate = block.timestamp;
        alpha_.price = price_;
        alphaList.push(id_);
    }

    function setAlphaStatus(uint256 id_, bool status_) authorised external {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate != uint256(0), "Project does not exists");

        alpha_.isAvailable = status_;
    }

    function setAlphaAvailableSlots(uint256 id_, uint256 availableSlots_) authorised external {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate != uint256(0), "Project does not exists");

        alpha_.availableSlots = availableSlots_;
    }

    function setAlphaAvailableDays(uint256 id_, uint256 daysAvailable_) authorised external {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate != uint256(0), "Project does not exists");

        alpha_.daysAvailable = daysAvailable_;
    }

    function setAlphaPrice(uint256 id_, uint256 price_) authorised external {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate != uint256(0), "Project does not exists");

        alpha_.price = price_;
    }

    function getRegisteredAddresses(uint256 id_) external view returns(address[] memory) {
        address[] memory addresses = new address[](alphaConfig[id_].registeredAddresses.length());

        for (uint256 i = 0; i < alphaConfig[id_].registeredAddresses.length(); ++i) {
            addresses[i] = alphaConfig[id_].registeredAddresses.at(i);
        }

        return addresses;
    }

    function getAlphaConfig(uint256 id_) external view returns(bool, uint256, uint256, uint256, uint256) {
        Alpha storage alpha_ = alphaConfig[id_];
        require(alpha_.creationDate != uint256(0), "Project already exists");

        return (alpha_.isAvailable, alpha_.availableSlots, alpha_.daysAvailable, alpha_.creationDate, alpha_.price);
    }

    function enroll(uint256 id_) external {
        Alpha storage alpha_ = alphaConfig[id_];

        require(alpha_.isAvailable, "Project is not available");
        if (alpha_.daysAvailable != uint256(0)) {
            require(alpha_.creationDate + alpha_.daysAvailable * DAYS >= block.timestamp, "End date reached");
        }
        if (alpha_.availableSlots != uint256(0)) {
            require(alpha_.registeredAddresses.length() < alphaConfig[id_].availableSlots, "Available slots filled");
        }
        require(IERC721(humansAddress).balanceOf(_msgSender()) > 0, "You do not own humans");

        alphaConfig[id_].registeredAddresses.add(msg.sender);

        if (alpha_.price != uint256(0)) {
            IERC20(tokenAddress).transferFrom(_msgSender(), tokenAddress, alpha_.price * ETHER);
        }
    }

}

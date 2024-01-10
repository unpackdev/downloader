// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Marketplace is OwnableUpgradeable {
    
    struct Listing { 
        string nameAndDesc;
        string image;
        uint256 slots;
        uint256 expiry;
        uint256 price;
        uint256 maxCount;
        string socials;
        bool deleted;
    }

    struct Whitelist { 
        uint256 listingIndex;
        string discordId;
        uint256 count;
        uint256 total;
    }

    mapping (address => bool) public admins;
    mapping (address => Whitelist[]) public owned;
    // Index to number of bought
    mapping (address => mapping (uint256=> uint256)) public bought;

    Listing[] public listings;

    address public essence;
    address public babyDraco;
    uint256 public minHold;
    address public draco;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event Purchase(address indexed _from, uint256 _index, string _discordId, uint256 _count, uint256 _total);

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function setEssence(address _essence) public onlyOwner {
        essence = _essence;
    }

    function setDraco(address _draco) public onlyOwner {
        draco = _draco;
    }

    function setBabyDraco(address _babyDraco) public onlyOwner {
        babyDraco = _babyDraco;
    }

    function setMinHold(uint256 _minHold) public onlyOwner {
        minHold = _minHold;
    }

    function setAdmin(address _admin, bool _permission) public onlyOwner {
        admins[_admin] = _permission;
    }

    function addListing(string calldata _nameAndDesc, string calldata _image, uint256 _slots, uint256 _expiry, uint256 _price, uint256 _maxCount, string calldata _socials) public onlyAdmin {
        Listing memory listing = Listing(_nameAndDesc, _image, _slots, _expiry, _price, _maxCount, _socials, false);
        listings.push(listing);
    }

    function editListing(uint256 _index, string calldata _nameAndDesc, string calldata _image, uint256 _slots, uint256 _expiry, uint256 _price, uint256 _maxCount, string calldata _socials) public onlyAdmin {
        listings[_index].nameAndDesc = _nameAndDesc;
        listings[_index].image = _image;
        listings[_index].slots = _slots;
        listings[_index].expiry = _expiry;
        listings[_index].price = _price;
        listings[_index].maxCount = _maxCount;
        listings[_index].socials = _socials;
    }

    function removeListing(uint256 _index) public onlyAdmin {
        listings[_index].deleted = true;
    }

    function getListings() public view returns (Listing[] memory) {
        return listings;
    }

    function getOwned(address _address) public view returns (Whitelist[] memory) {
        return owned[_address];
    }

    function purchase(uint256 _index, string calldata _discordId, uint256 _count) public {
        Listing storage listing = listings[_index];
        uint256 total = listing.price * _count;
        uint256 addedCount = bought[msg.sender][_index] + _count;
        require(tx.origin == msg.sender,                                 "?");
        require(!listing.deleted,                                        "Deleted");
        require(block.timestamp < listing.expiry,                        "Expired");
        require(_count > 0 && _count <= listing.slots,                   "No slots");
        require(addedCount <= listing.maxCount,                          "Exceed limit");
        require(total <= IERC20(essence).balanceOf(msg.sender),          "Not enough balance");
        require(IERC721(draco).balanceOf(msg.sender) >= minHold || IERC721(babyDraco).balanceOf(msg.sender) >= minHold,    "Need to hold min draco");
        listing.slots -= _count;
        bought[msg.sender][_index] = addedCount;
        owned[msg.sender].push(Whitelist(_index, _discordId, _count, total));
        IERC20(essence).transferFrom(msg.sender, BURN_ADDRESS, total);
        emit Purchase(msg.sender, _index, _discordId, _count, total);
    }
}
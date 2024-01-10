// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
     
contract ExpandablesMarketplace is Ownable {

    uint256 public whitelistCounter;
    mapping(uint => Whitelist) whitelists;

    mapping(address => string) public names;
    mapping(uint => mapping(address => bool)) _hasPurchased;
    address public bambooAddress;

    struct Whitelist {
        uint256 id;
        uint256 price;
        uint256 amount;
    }

    event Purchase (uint256 indexed _id, address indexed _address);
    event PurchasedWithName (uint256 indexed _id, address indexed _address, string name);

    constructor(address _bambooAddress) { 
        bambooAddress = _bambooAddress;
    }

    function addWhitelist(uint256 _amount, uint256 _price) external onlyOwner {
        Whitelist memory wl = Whitelist(
            whitelistCounter,
            _price * 10 ** 18,
            _amount
        );

        whitelists[whitelistCounter++] = wl;
    }

    function purchase(uint256 _id) public {
        require(
            whitelists[_id].amount != 0,
            "No spots left"
        );
       require(
           !_hasPurchased[_id][msg.sender],
           "Address has already purchased");

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchased[_id][msg.sender] = true;
        IBamboo(bambooAddress).burnFrom(msg.sender, whitelists[_id].price);

        emit Purchase(_id, msg.sender);
    }

    function purchaseWithName(uint256 _id, string memory name) public {
        require(
            whitelists[_id].amount != 0,
            "No spots left"
        );
       require(
           !_hasPurchased[_id][msg.sender],
           "Address has already purchased");

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchased[_id][msg.sender] = true;
        names[msg.sender] = name;
        IBamboo(bambooAddress).burnFrom(msg.sender, whitelists[_id].price);

        emit PurchasedWithName(_id, msg.sender, name);
    }

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function hasPurchased(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchased[_id][_address];
    }

    function setBambooAddress(address _bambooAddress) public onlyOwner {
        bambooAddress = _bambooAddress;
    }
}

interface IBamboo is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}
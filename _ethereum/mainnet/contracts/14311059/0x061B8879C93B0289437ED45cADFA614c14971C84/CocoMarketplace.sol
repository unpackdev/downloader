// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICoco.sol";
import "./Ownable.sol";
            
// @author 0xBori <https://twitter.com/0xBori>   
contract CocoMarketplace is Ownable {

    uint256 public whitelistCounter;
    mapping(uint => Whitelist) whitelists;
    mapping(uint => mapping(address => bool)) _hasPurchased;
    address public cocoAddress;

    struct Whitelist {
        uint256 id;
        uint256 price;
        uint256 amount;
    }

    event Purchase (uint256 indexed _id, address indexed _address);

    constructor() { 
        cocoAddress = 0x133B7c4A6B3FDb1392411d8AADd5b8B006ad69a4;
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
        ICoco(cocoAddress).burnFrom(msg.sender, whitelists[_id].price);

        emit Purchase(_id, msg.sender);
    }

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function hasPurchased(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchased[_id][_address];
    }

    function setCocoAddress(address _cocoAddress) public onlyOwner {
        cocoAddress = _cocoAddress;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract GongMasterWL is Ownable {

    uint256 public _price = 0.05 ether; //static price in wei
    mapping(address => bool) public whitelistedAddresses;
    uint8 public numAddressesWhitelisted;
    bool public paused  =  false;


    function price_rev() public view returns (uint) {
        return _price;
    }

    function changePrice(uint256 newPrice) public onlyOwner{
        _price = newPrice;
        _price;
    }

    function transfer(address payable _to, uint _amount) public onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function addAddressToWhitelist() public payable {
        require(paused == false, "White Listing Not Allowed Contact admin");
        require ( _price == msg.value);
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Pausable.sol";
import "./Ownable.sol";

import "./Grave.sol";
import "./GraveStone.sol";

contract FreeMintWhitelist is Pausable, Ownable {
    Grave grave;
    GraveStone graveStone;

    bool private canFreeMint;

    event LogFreeMint(address, uint256 x, uint256 y);

    mapping(address => bool) freeWhitelistedAddresses;

    mapping(address => uint256) public freeMintCounter;
    

    constructor(address graveContractAddress, address graveStoneAddress) {
        grave = Grave(graveContractAddress);
        graveStone = GraveStone(graveStoneAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function freeMint(uint256 x, uint256 y) public isFreeWhitelist whenNotPaused payable {
        uint256 expTime = block.timestamp + 180 days;
        if (freeMintCounter[msg.sender] >= 1) revert();
        grave.safeMintWithLock(msg.sender, x, y, expTime);
        graveStone.safeMintWithLock(msg.sender, expTime);
        freeMintCounter[msg.sender] = freeMintCounter[msg.sender] + 1;
    }

    modifier isFreeWhitelist() {
      require(freeWhitelistedAddresses[msg.sender], "Free Whitelist: You need to be fre whitelisted");
      _;
    }

    function addFreeManyWhiteUsers(address[] memory _addresses) public onlyOwner {
        require(_addresses.length < 10000);
        for (uint index = 0; index < _addresses.length; index++) {
             freeWhitelistedAddresses[_addresses[index]] = true;
        }
    }

    function addFreeWhiteUser(address _address) public onlyOwner {
      freeWhitelistedAddresses[_address] = true;
    }

    function removeFreeWhiteUser(address _address) public onlyOwner {
        freeWhitelistedAddresses[_address] = false;
    }

    function verifyFreeWhiteUser(address _address) public view returns(bool) {
      return freeWhitelistedAddresses[_address];
    }
}
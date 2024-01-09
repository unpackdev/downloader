// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicBatsMetadata.sol";

abstract contract BasicBatsPresale is BasicBatsMetadata {
    
    constructor(string memory _baseURI) BasicBatsMetadata(_baseURI) {}
    
    mapping(address => uint) presaleAddrStatus;

    uint presalePrice = 0.07 ether;
    
    modifier canMintPresale(uint _num) {
        require(presaleAddrStatus[msg.sender] > 0 && _num <= presaleAddrStatus[msg.sender]);
        _;
    }
    
    function addPresaleAddrs(address[] calldata _presaleAddrs, uint _num) external onlyOwner {
        for (uint i = 0; i < _presaleAddrs.length; i++) {
            presaleAddrStatus[_presaleAddrs[i]] = _num;
        }
    }
    
    function rmPresaleAddrs(address[] calldata _presaleAddrs) external onlyOwner {
        for (uint i = 0; i < _presaleAddrs.length; i++) {
            presaleAddrStatus[_presaleAddrs[i]] = 0;
        }
    }
    
    function presaleMint(uint _num) external payable canMintPresale(_num) nonReentrant {
        require(presaleOpen, "Presale should be open to mint");

        uint reserved =  presaleAddrStatus[msg.sender];
        _mintBasicBats(_num, presalePrice, msg.sender);
        presaleAddrStatus[msg.sender] = reserved - _num;
        delete reserved;
    }
    
    function switchPresaleStatus() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    
}
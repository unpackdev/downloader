// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

abstract contract IERC721 {
    function mint(address to) external virtual;
}

contract ERC721MinterFree is Ownable {
    IERC721 public erc721;

    //used to verify whitelist user
    mapping(address => uint) public mintQuantity;
    address public devPayoutAddress;
    mapping(address => uint) public claimed;
    mapping(address => bool) public whitelisted;

    constructor(IERC721 erc721_) {
        erc721 = erc721_;
        devPayoutAddress = address(0xc891a8B00b0Ea012eD2B56767896CCf83C4A61DD);
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setQuantity(address buyer, uint newQ_) public onlyOwner {
        mintQuantity[buyer] = newQ_;
    }

    function mint(uint quantity_) public {
        //requires that user is in whitelsit
        require(whitelisted[msg.sender], "Address not whitelisted.");

        //check mint quantity
        require(claimed[msg.sender] + quantity_ <= mintQuantity[msg.sender], "Already claimed.");

        //increase quantity that user has claimed
        claimed[msg.sender] = claimed[msg.sender] + quantity_;

        //mint quantity times
        for (uint i = 0; i < quantity_; i++) {
            erc721.mint(msg.sender);
        }
    }

    function addToWhitelist(address[] memory _whitelist) public onlyOwner {
        for (uint i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = true;
        }
    }
}

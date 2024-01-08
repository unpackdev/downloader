// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Math.sol";

contract MilkyBoys is ERC721, Ownable {
    uint256 private _tokenIds;

    uint256 public mintingFee;
    address payable private receiver;

    string internal _contractURI;
    string internal _tokenURI;

    constructor(
        string memory __contractURI, 
        string memory __tokenURI,
        address payable _receiver
    ) ERC721("MilkyBoys", "MB") {
        _contractURI = __contractURI;
        _tokenURI = __tokenURI;
        receiver = _receiver;
        _tokenIds = 0;
    }

    function safeMint(uint amount) external payable {
        require(amount < 9, "MilkyBoys: amount can't exceed 8");
        require(amount > 0, "MilkyBoys: amount too little");
        require(msg.value == mintingFee * amount, "MilkyBoys: insufficient fund");
        require(msg.sender != address(0), "MilkyBoys: empty address");
        require(_tokenIds < 999, "MilkyBoys: no more left to mint");

        uint iter = Math.min(999 - _tokenIds, amount);
        for (uint i = _tokenIds; i < iter + _tokenIds; i++) {
            _safeMint(msg.sender, i+1); // +1 because metadata starts with 1
        }
        _tokenIds += iter;
        receiver.transfer(mintingFee * iter);
        payable(msg.sender).transfer(mintingFee * (amount - iter));
    }

    function lastId() external view returns (uint256) {
        return _tokenIds;
    }

    function setReceiverAddress(address payable _receiver) external onlyOwner {
        receiver = _receiver;
    }

    function setMintingFee(uint256 _value) external onlyOwner {
        mintingFee = _value;
    }

    // Metadata
    function setTokenURI(string calldata _uri) external onlyOwner {
        _tokenURI = _uri;
    }
    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }
    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }
}
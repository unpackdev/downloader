// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract BingDwenDwen is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    uint256 public immutable maxPerAddressDuringMint;

    string public _baseTokenURI;
    uint256 public _mintPrice = 0.05 ether;
    string private  _suffix = ".json";

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("BingDwenDwen", "BDD", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
    }

    function mint(uint256 _mintAmount) public  payable nonReentrant  {
        require(_mintAmount > 0, "Cant mint 0");
        require(tx.origin == msg.sender, "The caller is another contract");
        require(totalSupply() + _mintAmount <= collectionSize, "reached max supply");
        require(msg.value >= _mintPrice * _mintAmount, "no enough money");
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), _suffix)) : "";
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
        return ownershipOf(tokenId);
    }
}

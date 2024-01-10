//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract BajmolCollectible is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    uint public constant MAX_SUPPLY = 10000;
    uint public constant PRICE = 0.05 ether;
    uint public constant MAX_PER_MINT = 10;
    uint public constant RESERVE_BATCH = 10;

    bool public reveal = false;
    string public baseTokenURI;
    
    constructor(string memory baseURI) ERC721("Bajmol Collectible", "BAJMOL") {
        baseTokenURI = baseURI;
    }
    
    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(RESERVE_BATCH) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < RESERVE_BATCH; i++) {
            _mintSingleNFT();
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function toggleReveal(string memory _baseTokenURI) public onlyOwner {
        reveal = !reveal;
        baseTokenURI = _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return reveal ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : baseURI;
    }

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }
    
    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
    
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract PastelPyramids is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 5000;
    uint public constant RESERVE_NUM = 20;
    uint public constant PRICE = 0.01 ether;
    uint public constant MAX_PER_MINT = 5;
    uint public constant MAX_FREE_MINT_PER_ADDR = 5;

    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("Pastel Pyramids", "PASTPYR") {
        setBaseURI(baseURI);
    }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(RESERVE_NUM) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < RESERVE_NUM; i++) {
            _mintSingleNFT();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function totalNFTsMinted() public view returns (uint) {
        return _tokenIds.current();
    }

    function mintFreeNFTs(uint _count) public {
        uint totalMinted = _tokenIds.current();
        uint tokenBalance = balanceOf(msg.sender);

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(tokenBalance < MAX_FREE_MINT_PER_ADDR && tokenBalance.add(_count) <= MAX_FREE_MINT_PER_ADDR , "Cannot exceed MAX_FREE_MINT_PER_ADDR.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
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

    function balanceOfOwner(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    function donate() public payable {
        // Thank you
    }

    function withdraw() public payable onlyOwner {
        // Allows me to withdraw any donated funds
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

}
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract NFL is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 625;
    uint256 public mintPrice = 0 ether;
    uint256 public maxBalance = 2;
    uint256 public maxPerMint = 2;

    string baseURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory initBaseURI) ERC721("Non-Fungible Life", "NFL") {
        setBaseURI(initBaseURI);
    }

    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            _count > 0 && _count <= maxPerMint,
            "Can only mint 2 tokens at a time."
        );
        require(
            msg.value >= mintPrice.mul(_count),
            "Not enough ether to purchase NFTs."
        );
        require(
            balanceOf(msg.sender) + _count <= maxBalance,
            "Sale would exceed max balance"
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function reserveNFTs() public onlyOwner {
        uint256 totalMinted = _tokenIds.current();

        require(
            totalMinted.add(2) <= MAX_SUPPLY,
            "Not enough NFTs left to reserve"
        );

        for (uint256 i = 0; i < 2; i++) {
            _mintSingleNFT();
        }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxPerMint) public onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}

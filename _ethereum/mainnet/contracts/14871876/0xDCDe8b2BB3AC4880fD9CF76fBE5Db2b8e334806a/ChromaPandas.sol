// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ChromaPandas is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => uint256) private mintedFreeAmount;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public price = 0.003 ether;
    uint256 public maxMintPerTx = 5;
    uint256 public maxFreeMintPerWallet = 5;
    uint256 public maxFreeSupply = 250;
    uint256 public maxSupply = 750;
    bool public status = false;

    constructor(string memory initBaseURI) ERC721A("Chroma Pandas", "PANDAS") {
        baseURI = initBaseURI;
        _safeMint(msg.sender, 3);
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < maxFreeSupply + 1) &&
            (mintedFreeAmount[msg.sender] + count <= maxFreeMintPerWallet)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "Exceeds max supply.");
        require(status, "Minting is not live yet.");
        require(count < maxMintPerTx + 1, "Max per TX reached.");

        if (isFree) {
            mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeMaxSupply(uint256 amount) external onlyOwner {
        maxFreeSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        maxFreeMintPerWallet = amount;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setStatus() external onlyOwner {
        status = !status;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
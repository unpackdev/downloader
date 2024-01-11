// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract EthereumSaviors is ERC721A, Ownable {
    using Strings for uint256;
    mapping(address => uint256) private _mintedFreeAmount;
    string public baseURI;

    uint256 public _mintPrice = 0.004 ether;

    uint256 public _maxMintPerTx = 40;
    uint256 public _maxFreeMintPerWallet = 5;

    uint256 public _maxFreeSupply = 1000;
    uint256 public _maxSupply = 4444;

    bool public _mintStarted = true;

    constructor(string memory initBaseURI) ERC721A("EthereumSaviors", "ES") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = _mintPrice;
        bool isFree = ((totalSupply() + count < _maxFreeSupply + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= _maxFreeMintPerWallet)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < _maxSupply + 1, "SOLD OUT.");
        require(_mintStarted, "Minting is not live yet.");
        require(count < _maxMintPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        _maxFreeSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        _maxFreeMintPerWallet = amount;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        _mintPrice = _newPrice;
    }

    function setStarted() external onlyOwner {
        _mintStarted = !_mintStarted;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}

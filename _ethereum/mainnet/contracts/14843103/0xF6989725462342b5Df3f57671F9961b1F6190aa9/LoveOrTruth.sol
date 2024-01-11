// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract LoveOrTruth is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.003 ether;

    uint256 public maxMintPerTx = 10;

    uint256 public maxFreeMintPerAddr = 5;

    uint256 public maxFreeSupply = 500;

    uint256 public maxSupply = 4105;

    bool public mintEnabled = true;

    mapping(address => uint256) private _mintedFreeAmount;
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("LoveOrTruth", "LOT") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < maxFreeSupply + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreeMintPerAddr)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "No more bears");
        require(mintEnabled, "Minting is not live yet, hold on bear.");
        require(count < maxMintPerTx + 1, "Max per TX reached.");

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
        maxFreeSupply = amount;
    }

    function saleStateToggle() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./SimpleAccess.sol";

interface IHoney {
    function burn(address user, uint256 amount) external;
}

contract FlowerFamMintPass is ERC721A, SimpleAccess {
    using Strings for uint256;

    IHoney public honey;
    string public baseURIString = "https://storage.googleapis.com/flowerfam/metadata/honeylist/";
    uint256 public maxPasses = 270;
    uint256 public passPrice = 169 ether;
    mapping(address => uint256) public redeemedPasses;

    uint256 public mintOpen = 1653062400;
    bool public transfersOpen;

    constructor(address _honey) ERC721A("Honey List By Flower Fam", "HONEYLIST") {
        honey = IHoney(_honey);
        _mint(msg.sender, 1);
    }

    function mintOne() external {
        mint(1);
    }

    function mint(uint256 amount) public {
        require(block.timestamp >= mintOpen, "Mint not open");
        require(totalSupply() + amount <= maxPasses, "Passes sold out");
        honey.burn(msg.sender, passPrice * amount);

        _mint(msg.sender, amount);
    }

    function userPassesLeft(address owner) external view returns (uint256) {
        return (balanceOf(owner) * 2) - redeemedPasses[owner];
    }

    function redeemPasses(address owner, uint256 amount) external onlyAuthorized {
        redeemedPasses[owner] += amount;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override view {
        require(transfersOpen || from == address(0), "No transfers allowed except minting");
    }

    function setTransfersOpen(bool _set) external onlyOwner {
        transfersOpen = _set;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function setHoney(address hny) external onlyOwner {
        honey = IHoney(hny);
    }

    function setMaxPasses(uint256 max) external onlyOwner {
        maxPasses = max;
    }

    function setPassPrice(uint256 price) external onlyOwner {
        passPrice = price;
    }

    function setMintOpen(uint256 newOpen) external onlyOwner {
        mintOpen = newOpen;
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
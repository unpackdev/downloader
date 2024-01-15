// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NotPudgyPenguin is ERC721A, Ownable {
    uint256 public MaxPerTxn = 20;
    uint256 public MaxFreePerWallet = 3;
    bool public mintEnabled = false;
    uint256 public totalFree = 2000;
    uint256 public maxSupply = 8888;
    uint256 public price = 0.004 ether;
    string public baseURI =
        "ipfs://QmQuWTLeffra82yyozToxNuBq9TR8uD1qcA9Rtqd69rEid/";

    constructor() ERC721A("NotPudgyPenguin", "NPP") {}

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function ownerMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function mint(uint256 amount) external payable {
        require(totalSupply() + amount <= maxSupply, "no more");
        require(mintEnabled, "Sale is not live");

        uint256 cost = price;
        if (
            totalSupply() + amount <= totalFree &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }
        require(msg.value >= amount * cost, "more money!");

        _safeMint(msg.sender, amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}

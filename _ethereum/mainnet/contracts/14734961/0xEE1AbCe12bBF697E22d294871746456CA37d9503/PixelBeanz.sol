// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


contract PixelBeanz is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public cost = 0.02 ether;
    uint256 public maxSupply = 4500;
    uint256 public maxPerTx = 20;
    uint256 public reserved = 50;

    bool public saleOpen = false;
    string public baseExtension = '.json';
    string private _baseTokenURI;

    constructor() ERC721A("Pixel Beanz", "PBZ") {}

    function mint(uint256 quantity) external payable {
        require(saleOpen, "Ooops sale is paused");
        uint256 supply = totalSupply();

        require(quantity > 0, "cannot mint 0");
        require(quantity <= maxPerTx, "exceed max per tx");
        require(supply + quantity <= maxSupply - reserved, "exceed max supply of beanz");

        if (supply < 500) {
            require(msg.value >= 0 * quantity, "Yay free mint");
        } else {
            require(msg.value >= cost * quantity, "Ooops not enough ether");
        }
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

  
    // Owner Only
    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function giveAway(address receiver, uint256 quantity) external onlyOwner {
        require(quantity <= reserved);
        reserved -= quantity;
        _safeMint(receiver, quantity);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function updateSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function updateCost(uint256 newCost) external onlyOwner {
        cost = newCost;
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
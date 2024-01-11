// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


contract NotTrippinApe is ERC721A, Ownable {
    using Strings for uint256;

    bool public saleOpen = false;
    string public baseExtension = '.json';
    string private _baseTokenURI;

    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 5000;
    uint256 public freeMintQuantity = 500;

    mapping(address => uint256) public mintedPerWallet; 

    constructor() ERC721A("Not Trippin Ape", "NTA") {}

    function mint(uint256 quantity) external payable {
        require(saleOpen, "Ooops sale is paused");
        uint256 supply = totalSupply();
        require(quantity > 0, "cannot mint 0");
        require(supply + quantity <= maxSupply, "exceed max supply of apes");

        if (supply < freeMintQuantity) {
            require(mintedPerWallet[msg.sender] + quantity < 11, "exceeded max free mint per wallet");
            require(msg.value >= 0 * quantity, "Yay free mint");
            mintedPerWallet[msg.sender] += quantity;

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


    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function updateSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function updateCost(uint256 newCost) external onlyOwner {
        cost = newCost;
    }

    function updateFreeMint(uint256 newQty) external onlyOwner {
        freeMintQuantity = newQty;
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
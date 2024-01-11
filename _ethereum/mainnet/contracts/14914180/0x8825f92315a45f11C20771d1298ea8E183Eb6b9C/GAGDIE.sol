// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
contract GAGDIE is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supplyGAGDIE;
    uint256 public GD;
    uint256 public maxPerTxn = 100;
    uint256 public og = 10;
    uint256 public price   = 0.0069 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("GAGDIE", "GAGDIE", 500) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > GD)
        {
        require(totalSupply() + count < supplyGAGDIE, "max supply reached.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price <= msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
        }
    else 
        {
        require(!walletCount[msg.sender], " not allowed");
        _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
        }

    }

    function whitelist() external onlyOwner {
            _safeMint(_msgSender(), og);
    }
      
    function setSupply(uint256 _newSupplyGD) public onlyOwner {
        supplyGAGDIE = _newSupplyGD;
    }

    function setGD(uint256 _newGD) public onlyOwner {
        GD = _newGD;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setOG(uint256 _newOG) public onlyOwner {
        og = _newOG;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}
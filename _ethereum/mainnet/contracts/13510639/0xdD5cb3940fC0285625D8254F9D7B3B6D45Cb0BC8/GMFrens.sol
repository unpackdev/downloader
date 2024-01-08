// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract GMFrens is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private baseURI;
    uint256 public maxSupply = 4269;

    uint256 public price = 0.069420 ether;

    bool public presaleActive = false;
    bool public saleActive = false;

    mapping (address => uint256) public presaleWhitelist;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive,                              "Presale must be active to mint");
        require(reserved > 0,                               "No tokens reserved for this address");
        require(numberOfMints <= reserved,                  "Can't mint more than reserved");
        require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        require(supply + numberOfMints <= maxSupply,        "Exceeds max supply");

        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint(msg.sender, supply + i);
        }
    }

   function mint(uint256 numberOfMints) public payable {
      uint256 supply = totalSupply();
      require(saleActive,                                 "Sale must be active to mint");
      require(numberOfMints > 0 && numberOfMints < 6,     "Invalid purchase amount");
      require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
      require(supply + numberOfMints <= maxSupply,        "Exceeds max supply");
      for(uint256 i; i < numberOfMints; i++) {
          _safeMint(msg.sender, supply + i);
        }
    }

    function editPresale(address[] calldata presaleAddresses, uint256[] calldata amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
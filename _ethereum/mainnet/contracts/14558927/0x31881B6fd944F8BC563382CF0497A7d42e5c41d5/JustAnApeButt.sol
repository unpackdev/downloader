// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
contract JustAnApeButt is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supply;
    uint256 public maxPerTxn = 101;
    uint256 public init = 50;
    uint256 public price   = 0.0069 ether;


    constructor() ERC721A("Just An Ape Butt", "JustAnApeButt", 500) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < supply, "Excedes max supply.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function dev() external onlyOwner {
            _safeMint(_msgSender(), init);
    }
      
    function setSupply(uint256 _newSupply) public onlyOwner {
        supply = _newSupply;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setInit(uint256 _newInit) public onlyOwner {
        init = _newInit;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}
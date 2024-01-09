// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
contract Loliverse is ERC721A, Ownable {
    string  public baseURI;
    
    uint256 public supplyLoli;
    uint256 public freeLoli;
    uint256 public maxPerTxn = 21;
    uint256 public price = 0.03 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("Loliverse", "LOLI", 20) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < supplyLoli, "Excedes max supply.");
        require(totalSupply() + 1  > freeLoli, "Public sale is not live yet.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function freeMint() public payable {
        require(totalSupply() + 1 <= freeLoli, "Public sale is live");
        require(!walletCount[msg.sender], " 1 free mint per wallet");
         _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
    }

    function airdrop() external onlyOwner {
            _safeMint(_msgSender(), 10);
    }
      
    function setSupply(uint256 _newSupplyLoli) public onlyOwner {
        supplyLoli = _newSupplyLoli;
    }

    function setfreeLoli(uint256 _newfreeLoli) public onlyOwner {
        freeLoli = _newfreeLoli;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTxnLimit(uint256 _newLimit) public onlyOwner {
        maxPerTxn = _newLimit;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}
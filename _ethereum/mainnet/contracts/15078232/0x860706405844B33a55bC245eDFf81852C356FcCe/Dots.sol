// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721B.sol";
import "./SafeMath.sol";

  contract Dots is ERC721B, Ownable {
    using Strings for uint256;
    string public baseURI = "";
    bool public isSaleActive = false;
    mapping(address => uint256) private _mintClaimed;
    uint256 public constant MAX_TOKENS = 6666;
    uint256 public constant FREE_MINTS = 666;
    uint256 public tokenPrice = 5000000000000000;
    uint256 public constant maxTokenPurchase = 2;

    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public devReserve = 5;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("Dots", "DT") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
      }


      function _tokenPrice() internal view virtual returns (uint256) {
        return tokenPrice;
      }

       function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
      }

    function activateSale() external onlyOwner {
        isSaleActive = !isSaleActive;
      }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function Withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
      }

    function reserveTokens(address dev, uint256 reserveAmount)
    external
    onlyOwner
      {
        require(
        reserveAmount > 0 && reserveAmount <= devReserve,
          "Dev reserve empty"
        );
        totalSupply().add(1);
        _mint(dev, reserveAmount);
      }
    function mintNFT(address to, uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxTokenPurchase,
          "Can Mint only 2 per Wallet"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over max per transaction"
        );
        require(
          _mintClaimed[msg.sender].add(quantity) <= maxTokenPurchase,
          "Only 2 Mints per Wallet"
        );
        if(totalSupply()<=FREE_MINTS){
           _mintClaimed[msg.sender] += quantity;
           _mint(to, quantity);
        }else{
          require(
          msg.value >= tokenPrice.mul(quantity),
          "Invalid amount sent"
        );
        _mintClaimed[msg.sender] += quantity;
        _mint(to, quantity);
        }
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
    
        string memory currentBaseURI = _baseURI();
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
            
      }
}


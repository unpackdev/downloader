// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721B.sol";
import "./SafeMath.sol";


  /*
  --Information for Mint--
  One Free Mint per Wallet
  10 Mints per tx
  After free mint each mint will cost 0.001 eth
  */
  
  contract TheFrench is ERC721B, Ownable {
    using Strings for uint256;
    string public baseURI = "";
    bool public isSaleActive = false;
    mapping(address => bool) public _freeMintClaimed;
    uint256 public constant MAX_TOKENS = 9999;
    uint256 public tokenPrice = 1000000000000000;
    uint256 public constant maxPerTX = 10;

    using SafeMath for uint256;
    using Strings for uint256;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("TheFrench", "FR") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }
      
      function _price() internal view virtual returns (uint256) {
        return tokenPrice;
      }
      

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
      }

      function setPrice(uint256 _newTokenPrice) public onlyOwner {
      tokenPrice = _newTokenPrice;
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
        totalSupply().add(1);
        _mint(dev, reserveAmount);
      }
    function Mint(address to, uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxPerTX,
          "Can Mint only 10 per tx"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over Max Supply"
        );

        if( _freeMintClaimed[msg.sender] != true){
           _freeMintClaimed[msg.sender] = true;
          require(
            msg.value >= tokenPrice.mul(quantity-1),
            "Invalid ETH Sent, Anything over One Free Mint is 0.001 eth"
            );
            _mint(to, quantity);
        }else{
          require(
            msg.value >= tokenPrice.mul(quantity),
         "0.001 eth per token"
        );
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


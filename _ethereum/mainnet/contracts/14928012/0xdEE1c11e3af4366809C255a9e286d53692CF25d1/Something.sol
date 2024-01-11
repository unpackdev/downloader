// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721B.sol";
import "./SafeMath.sol";

contract Something is ERC721B, Ownable {
    using Strings for uint256;
    
    string private baseURI;
    string public hiddenURI = ""; 
    bool public isSaleActive = false;
    bool public isRevealed = false;
    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant tokenPrice = 20000000000000000;
    uint256 public constant maxTokenPurchase = 15;
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public devReserve = 1;
    event SomethingMinted(uint256 tokenId, address owner);

    constructor() ERC721B("Something", "ST") {}
     
     function _baseURI() internal view virtual  returns (string memory) {
        return baseURI;
      }
    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
      }
      function setHiddenURI(string memory _newHiddenURI) public onlyOwner {
        hiddenURI = _newHiddenURI;
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
          "Dev reserve depleted"
        );
        totalSupply().add(1);
        _mint(dev, reserveAmount);
      }
    function mintSomething(address to, uint256 quantity) external payable {
        require(isSaleActive, "Sale must be active to mint.");
        require(
          quantity > 0 && quantity <= maxTokenPurchase,
          "Mint Something"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Too Much"
        );
        require(
          msg.value >= tokenPrice.mul(quantity),
          "Send Something"
        );
        _mint(to, quantity);
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
        string memory currentHiddenURI = _hiddenURI();
    
        if (isRevealed == false) {
          return
            currentHiddenURI;
        }
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
      }
}


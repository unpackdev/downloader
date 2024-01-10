// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";


contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter _tokenIds;

    bool public isActive = false;  
    bool public isReveal = false;  
    uint public salePrice = 50000000000000000;
    uint public donationPrice = 20000000000000000;
    uint256 public constant TOKEN_SUPPLY = 10000;
    string internal baseURI;  
    string internal hiddenURI;  

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
      _tokenIds.increment();
    }

  function airdrop(address _to, uint256 _nb) external onlyOwner {
        for (uint32 i = 0; i < _nb; i++) {
            _mint(_to);
        }
    }

    function _mint(address _to) internal returns (uint256) {
        _safeMint(_to, _tokenIds.current());
        _tokenIds.increment();
        return _tokenIds.current();
    }

   function mint(uint _nb, address payable _donateTo, uint _donationPrice) public payable {
        require(isActive, "Sale is currently not active.");
        require(_nb > 0, "You must order at least 1 piece.");
        require(TOKEN_SUPPLY >= _nb + _tokenIds.current(), "Not enough tokens left to buy.");
     
        for (uint256 i = 0; i < _nb; i++) {
            _safeMint(msg.sender, _tokenIds.current());
             _tokenIds.increment();
        }

        _donateTo.transfer(_donationPrice * _nb);
    }

   // Transfer
   function transfer(address payable _to, uint amount) public payable onlyOwner {
        _to.transfer(amount);
    }

   // Sale price
    function setSalePrice(uint _salePrice) public onlyOwner {
        salePrice = _salePrice;
    }

   // Donation price
   function setDonationprice(uint _donationPrice) public onlyOwner {
        donationPrice = _donationPrice;
    }
    
    function setIsActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
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

    if (isReveal == false) {
      return hiddenURI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
        : "";
  }

  function setIsReveal(bool _isReveal) public onlyOwner {
    isReveal = _isReveal;
  }
 
  function setHiddenURI(string memory _hiddenURI) public onlyOwner { 
    hiddenURI = _hiddenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
        return baseURI; 
  }
    
  function setBaseURI(string memory _newbaseURI) public onlyOwner {
    baseURI = _newbaseURI;
  }
}
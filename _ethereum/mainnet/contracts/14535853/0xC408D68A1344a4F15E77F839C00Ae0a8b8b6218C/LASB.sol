// SPDX-License-Identifier: GPL-3.0

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel



pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract LEGACYAPESPERMBANK is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 3333;
  uint256 public MaxperWallet = 10;
  bool public paused = false;

  constructor() ERC721A("LEGACY APE SPERM BANK", "LASB") {
    setBaseURI("ipfs://Qmd5DbGu4q6hMziNBqwyHEYZmBUsG4mTTR2DPypTu6TGvH/");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "LASB: oops contract is paused");
    uint256 supply = totalSupply();
    require(tokens > 0, "LASB: need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "LASB: We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet, "LASB: Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "LASB: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }

  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
    
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
      "ERC721AMetadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //only owner
  
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }


  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

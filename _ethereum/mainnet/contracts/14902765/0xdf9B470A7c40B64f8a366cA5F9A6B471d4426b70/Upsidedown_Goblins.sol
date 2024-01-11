// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract UpsidedownGoblins is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.005 ether;
  uint256 public maxSupply = 6969;
  uint256 public freesupply = 1000;
  uint256 public maxperwallet = 40;
  uint256 public maxpertx = 20;
  bool public paused = false;
  bool public revealed = false;
  mapping(address => bool) public freeclaimed;

  constructor() ERC721A("Upsidedown Goblins", "UPGB") {
    setNotRevealedURI("ipfs://bafybeifrucyaopasbl6pgr5jqxuwooxbhbc5qeq4fti6qgyywwiz5xfsf4/hidden.json");
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
    require(!paused, "UPGB: oops contract is paused");
    uint256 supply = totalSupply();
    require(tokens > 0, "UPGB: need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "UPGB: We Soldout");


    if(supply + tokens <= freesupply) {
      if(freeclaimed[_msgSender()] == false) {
       require(msg.value >= cost * (tokens - 1), "insufficnt cost");
       freeclaimed[_msgSender()] = true;
      } else {
        require(msg.value >= cost * tokens, "insufficnt cost");
        require(tokens <= maxpertx, "UPGB: max mint amount per tx exceeded");
        require(_numberMinted(_msgSender()) + tokens <= maxperwallet, "UPGB: Max NFT Per Wallet exceeded");
      }
    } else {
    require(tokens <= maxpertx, "UPGB: max mint amount per tx exceeded");
    require(_numberMinted(_msgSender()) + tokens <= maxperwallet, "UPGB: Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "insufficnt cost");
    }
    
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

      function setfreesupply(uint256 _newsupply) public onlyOwner {
    freesupply = _newsupply;
  }

        function setmaxperwallet(uint256 _limit) public onlyOwner {
    maxperwallet = _limit;
  }

      function setmaxpertx(uint256 _limit) public onlyOwner {
    maxpertx = _limit;
  }



  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

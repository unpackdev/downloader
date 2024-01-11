// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract TheStonersNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01  ether;
  uint256 public maxSupply = 5000;
  uint256 public MaxPerWallet = 40;
  uint256 public MaxPerTx = 20;
  bool public paused = false;

  constructor() ERC721A("The Stoners NFT", "TSNFT") {
    setBaseURI("ipfs://bafybeifoxhxzirtvfs5tb5z7utflsoiu3jzcs6x6q2cxhs2z3ckikdzsla/");
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
    require(!paused, "TSNFT: oops contract is paused");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSender()) + tokens <= MaxPerWallet, "TSNFT: Max NFT Per Wallet exceeded");
    require(tokens > 0, "TSNFT: need to mint at least 1 NFT");
    require(tokens <= MaxPerTx, "TSNFT: Max Per Tx Exceeded");
    require(supply + tokens <= maxSupply, "TSNFT: We Soldout");
    require(msg.value >= cost * tokens, "TSNFT: insufficient funds");

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

    function SetMaxPerWallet(uint256 _newperwallet) public onlyOwner {
    MaxPerWallet = _newperwallet;
  }

    function SetMaxPerTx(uint256 _newpertx) public onlyOwner {
    MaxPerTx = _newpertx;
  }

 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

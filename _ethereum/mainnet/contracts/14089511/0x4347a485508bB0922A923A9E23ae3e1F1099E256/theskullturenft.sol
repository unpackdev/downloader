// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract TheSkulltureNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public amountForDevs = 120;
  uint256 public cost = .00 ether;
  uint256 public maxSupply = 6667;
  uint256 public nftPerAddressLimit = 4;

  bool public paused = true;
  bool public revealed = false;
  bool public onlyPresale = true;

  address[] public presaleAddresses;

  mapping(address => uint256) public addressMintedBalance;


  constructor() ERC721A("The Skullture", "SKULL", 10) {
    setHiddenMetadataUri("ipfs://Qmd2bUkkT8EGA4NFn8ZqfDdW4gZMuMGny3jts6BJe8MR5U/hidden.json");
  }

  // public
  function mint(uint256 quantity) public payable {
    require(!paused, "we're not quite ready.");
    uint256 supply = totalSupply();
    require(quantity > 0, "you can't mint zero Skulltures.");
    require(quantity <= maxBatchSize, "can't mint this many at one time.");
    require(supply + quantity <= maxSupply, "not enough Skulltures left, sorry!");
    require(numberMinted(msg.sender) + quantity <= nftPerAddressLimit, "this would exceed your Skulltures per wallet limit.");

       if (msg.sender != owner()) {
        if(onlyPresale == true) {
            require(isPresale(msg.sender), "user is not Ancient or Primeval.");
                           
        }
        require(msg.value >= cost * quantity, "you require more minera, er, ETH.");
            }
        
        _safeMint(msg.sender, quantity);
    
  }

  function isPresale(address _user) public view returns (bool) {
    for (uint i = 0; i < presaleAddresses.length; i++) {
      if (presaleAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

    function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "You already did this or there's not enough left"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }
  

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function mintForAddress(uint256 quantity, address _receiver) public onlyOwner {
    _safeMint(_receiver, quantity);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setamountForDevs(uint256 _newamountForDevs) public onlyOwner {
    amountForDevs = _newamountForDevs;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyPresale(bool _state) public onlyOwner {
    onlyPresale = _state;
  }
  
  function presaleUsers(address[] calldata _users) public onlyOwner {
    delete presaleAddresses;
    presaleAddresses = _users;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function withdraw() public payable onlyOwner nonReentrant {
    
    (bool hs, ) = payable(0xcfb713326fBB55603CEC86971EE967FD83198945).call{value: address(this).balance * 50 / 100}("");
    require(hs);
    (bool os, ) = payable(0xb41bE272630123D01B1C2fa62852BFA85328936b).call{value: address(this).balance}("");
    require(os);
  }
}


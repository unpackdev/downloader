// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/////////////////////////////////////////////////////////
// Support OpenSea proxy registration
//   Reduce gas fees on secondary market sales
//
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/////////////////////////////////////////////////////////
contract C0FoNem is ERC721, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _supply;
  Counters.Counter private _supplyGD;
  Counters.Counter private _supplyBD;
  Counters.Counter private _supplyLK;
  Counters.Counter private _supplyVL;

  string public hiddenMetadataUri;
  string public uriPrefix;
  string public uriSuffix;

  uint256 public price;

  // Establish token maximums
  uint256 private constant _maxSupplySentinel = 10001;
  uint256 private constant _maxSupplyGDSentinel = 3001;
  uint256 private constant _maxSupplyBDSentinel = 2001;
  uint256 private constant _maxSupplyLKSentinel = 2501;
  uint256 private constant _maxSupplyVLSentinel = 2501;
  uint256 private constant _maxMintSentinel = 11;
  uint256 private constant _maxMintSentinelPresale = 4;

  mapping(uint256 => uint256) private _metadataFileIds;
  mapping(address => bool) private _vipList;

  address private  _shareholder02;
  address private _proxyRegistryAddress;

  bool public paused;
  bool public revealed;
  bool public presale;

  constructor() ERC721("FoNem | CRYPT00PPS", "F12") {
    revealed = false;
    presale = true;
    price = 0.07 ether;
    uriSuffix = ".json";
    hiddenMetadataUri = "ipfs://QmXFxeThfXvq4TiB41G6PbscySinVVrxqYHN3NUHwxYqJQ";
    _shareholder02 = 0xF0870Af00154e2fD68781e3d96EE8F911B140DA5; // mainnet
    _proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // mainnet

    // Mint project reserves (30 units)
    paused = false;
    privateMint(1, 10);
    privateMint(2, 10);
    privateMint(3, 5);
    privateMint(4, 5);
    paused = true;
  }

  //////////////////////////////////////////////////////////
  // PUBLIC FUNCTIONS
  ////
  function publicMint(uint256 gangID, uint256 quantity) external payable{
    ///////////////////////////////////////////
    // GUARD RAILS
    ////
    require(!paused, "Contract paused");
    require(gangID < 5, "Gang ID out of range");
    require(quantity < _maxSupplySentinel, "Quantity out of range");

    uint256 mintSentinel = _maxMintSentinel;

    if(presale) {
      mintSentinel = _maxMintSentinelPresale;
      require(vipListed(msg.sender), "You ain't VIP, lil folk");
    }

    require((balanceOf(msg.sender) + quantity) < mintSentinel, "Exceeds wallet limit");
    require(msg.value >= price * quantity, "Not enough dough");

    _privateMintForWallet(msg.sender, gangID, quantity);
  }

  function fileID(uint256 tokenId)
    external
    view
    returns(uint256) {
      require(tokenId < _maxSupplySentinel, "Out of range");
      return _metadataFileIds[tokenId];
  }

  function isApprovedForAll(address owner_, address operator)
    public
    view
    override
    returns(bool) {
    
    // Whitelist OpenSea proxy contract to avoid fees for listing
    //  individual tokens on the secondary market
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if(address(proxyRegistry.proxies(owner_)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner_, operator);
  }

  function maxMintQuantity()
    external
    view
    returns(uint256) {
      if(presale) return _maxMintSentinelPresale - 1;
      return _maxMintSentinel - 1;
  }

  function OGStatus(uint256 tokenId) external view returns (bool) {
    require(tokenId < 10001, "Out of range");

    // The first 200 tokens of each Mining Pool / Gang are
    //    considered OGs.
    uint256 ogLimit = 200;
    uint256 fileId_ = _metadataFileIds[tokenId];

    // GD Check | 1 to 200
    if(fileId_ < 3001) {
      if(fileId_ > ogLimit) return false;
      return true;
    }

    // BD Check | 3001 to 3200
    if(fileId_ < 5001) {
      if((fileId_ - 3000) > ogLimit) return false;
      return true;
    }

    // VL Check | 5001 to 5200
    if(fileId_ < 7501) {
      if((fileId_ - 5000) > ogLimit) return false;
      return true;
    }

    // LK Check | 7501 to 7700
    if((fileId_ - 7500) > ogLimit) return false;
    return true;
  }

  function tokensInWallet(address wallet)
    external
    view
    returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(wallet);
      uint256[] memory walletTokenIds = new uint256[](tokenCount);
      uint256 currentTokenId = 1;
      uint256 index = 0;

      while(index < tokenCount && currentTokenId < _maxSupplySentinel) {
        address currentTokenWallet = ownerOf(currentTokenId);

        if(currentTokenWallet == wallet) {
          walletTokenIds[index] = currentTokenId;
          index++;
        }

        currentTokenId++;
      }

      return walletTokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory) {
    
    require(_exists(tokenId), "Nonexistent token");

    if(false == revealed) return hiddenMetadataUri;

    string memory baseUri = _baseURI();

    return bytes(baseUri).length > 0
      ? string(abi.encodePacked(baseUri, _metadataFileIds[tokenId].toString(), uriSuffix))
      : "";
  }

  function totalSupply()
    external
    view
    returns(uint256) {
      return _supply.current();
  }

  function totalSupplyGD()
    external
    view
    returns(uint256) {
      return _supplyGD.current();
    }

  function totalSupplyBD()
    external
    view
    returns(uint256) {
      return _supplyBD.current();
    }
    
  function totalSupplyLK()
    external
    view
    returns(uint256) {
      return _supplyLK.current();
    }
    
  function totalSupplyVL()
    external
    view
    returns(uint256) {
      return _supplyVL.current();
    }

  function vipListed(address user) public view returns (bool) {
    return _vipList[user] ? true : false;
  }

  //////////////////////////////////////////////////////////
  // OWNER ONLY FUNCTIONS
  ////

  function privateMint(uint256 gangID, uint256 quantity)
    public
    onlyOwner {
    ////////////////////////////////////
    privateMintForWallet(owner(), gangID, quantity);
  }

  function privateMintForWallet(address wallet, uint256 gangID, uint256 quantity)
    public
    onlyOwner {
    ////////////////////////////////////
    require(!paused, "Contract paused");
    require(gangID < 5, "Gang ID out of range");
    require(quantity < _maxSupplySentinel, "Quantity out of range");

    _privateMintForWallet(wallet, gangID, quantity);
  }

  function addVIPs(address[] calldata accounts)
    external
    onlyOwner {
      // Iterate over all of the addresses and set to true
      for (uint256 i=0; i < accounts.length; i++) {
        _vipList[accounts[i]] = true;
      }
  }

  function setHiddenMetadataUri(string memory hiddenMetadataUri_)
    external
    onlyOwner {
      hiddenMetadataUri = hiddenMetadataUri_;
    }

  function setPaused(bool paused_)
    external
    onlyOwner {
      paused = paused_;
    }

  function setPresale(bool presale_)
    external
    onlyOwner {
      presale = presale_;
    }

  function setPrice(uint256 price_)
    external
    onlyOwner {
      price = price_;
    }

  function setRevealed(bool revealed_)
    external
    onlyOwner {
      revealed = revealed_;
    }

  function setUriPrefix(string memory uriPrefix_)
    external
    onlyOwner {
      uriPrefix = uriPrefix_;
    }

  function setUriSuffix(string memory uriSuffix_)
    external
    onlyOwner {
      uriSuffix = uriSuffix_;
    }

  function withdraw()
    external
    onlyOwner {
    // Pay owner2
    (bool sh02, ) = payable(_shareholder02).call{value: address(this).balance * 45 / 1000}("");
    require(sh02);

    // Pay owner1
    (bool sh01, ) = payable(owner()).call{value: address(this).balance}("");
    require(sh01);
  }

  // INTENTIONAL BUG
  function messageForTheBug() external pure returns (string memory) {
    return "Daddy loves his little Z-Bug! <3 <3 <3";
  }

  //////////////////////////////////////////////////////////
  // PRIVATE + INTERNAL FUNCTIONS
  ////

  function _baseURI()
    internal
    view
    virtual
    override
    returns(string memory) {
      return uriPrefix;
  }

  function _privateMintForWallet(address wallet, uint256 gangID, uint256 quantity)
    private
    {
    ////////////////////////////////////
    uint256 baselineBD = 3000;
    uint256 baselineVL = 5000;
    uint256 baselineLK = 7500;
    uint256 target;
    uint256 supply;

    if(1 == gangID) {
      supply = _supplyGD.current();
      target = supply + quantity;
      require(target < _maxSupplyGDSentinel, "Exceeds supply");
    } 
    else if(2 == gangID) {
      supply = _supplyBD.current();
      target = supply + quantity;
      require(target < _maxSupplyBDSentinel, "Exceeds supply");
    }
    else if(3 == gangID) {
      supply = _supplyVL.current();
      target = supply + quantity;
      require(target < _maxSupplyVLSentinel, "Exceeds supply");
    }
    else {
      supply = _supplyLK.current();
      target = supply + quantity;
      require(target < _maxSupplyLKSentinel, "Exceeds supply");
    }

    while(supply < target) {
      _supply.increment();
      _safeMint(wallet, _supply.current());

      // Perform the gang-specific minting tasks
      if(1 == gangID) {
        _supplyGD.increment();
        _metadataFileIds[_supply.current()] = _supplyGD.current();
        supply = _supplyGD.current();
      } else if(2 == gangID) {
        _supplyBD.increment();
        _metadataFileIds[_supply.current()] = baselineBD + _supplyBD.current();
        supply = _supplyBD.current();
      } else if(3 == gangID) {
        _supplyVL.increment();
        _metadataFileIds[_supply.current()] = baselineVL + _supplyVL.current();
        supply = _supplyVL.current();
      } else { 
        _supplyLK.increment();
        _metadataFileIds[_supply.current()] = baselineLK + _supplyLK.current();
        supply = _supplyLK.current();
      }
    }
  }
}
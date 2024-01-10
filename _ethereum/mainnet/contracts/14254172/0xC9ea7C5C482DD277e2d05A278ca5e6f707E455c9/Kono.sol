// SPDX-License-Identifier: MIT

pragma solidity ^0.8.00;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract Kono is ERC721Enumerable, Ownable, ContextMixin, NativeMetaTransaction {
  using Strings for uint256;

  struct Tier {
    string name;
    uint256 cost;
    uint256 supply;
  }

  string public baseURI;
  string public baseExtension = "";
  string public notRevealedUri;
  uint256 public maxSupply = 2999;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  bool public onSale = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  address proxyRegistryAddress;
  Tier[] public tiers;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _proxyRegistryAddress
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    proxyRegistryAddress = _proxyRegistryAddress;
    _initializeEIP712(_name);
    tiers.push(Tier("Private", 0.8 ether, 99));
    tiers.push(Tier("Pre-sale", 0.9 ether, 199));
    tiers.push(Tier("Public Sale Tier 1", 1.4 ether, 1999));
    tiers.push(Tier("Public Sale Tier 2", 1.6 ether, 2999));
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  function getPrice(uint256 _mintAmount) public view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 price = 0;
    uint256 lastMint = supply + _mintAmount;
    for(uint256 currentMint = supply + 1; currentMint <= lastMint; currentMint++) {
      if(currentMint <= tiers[0].supply) price += tiers[0].cost;
      else if (currentMint <= tiers[1].supply) price += tiers[1].cost;
      else if (currentMint <= tiers[2].supply) price += tiers[2].cost;
      else price += tiers[3].cost;
    }
    return price;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(onSale, "Not On Sale");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    if (msg.sender != owner()) {
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        if(onlyWhitelisted == true && supply < 199) { 
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= getPrice(_mintAmount), "insufficient funds");
    } 
    if(supply < tiers[0].supply) {
      require(supply + _mintAmount <= tiers[0].supply , "total mint exceeded tier");
      if(supply + _mintAmount == tiers[0].supply) onSale = false;
    } else if (supply < tiers[1].supply) {
      require(supply + _mintAmount <= tiers[1].supply , "total mint exceeded tier");
      if(supply + _mintAmount == tiers[1].supply) onSale = false;
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function safeOwnerTransfers(address[] calldata to, uint256[] calldata tokenId) public {
      require(to.length < 1, "need to transfer at least 1 token");
      require(to.length == tokenId.length, "number of address not equal to number of tokenId");
      for (uint256 i = 0; i < to.length; i++) {
        safeTransferFrom(msg.sender, to[i], tokenId[i]);
      }
    }

  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

  function setPrice(uint _tier, uint256 _price) public onlyOwner {
     require(_tier <= 3, "Invalid tier"); 
     tiers[_tier].cost = _price;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
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

  function setOnSale(bool _state) public onlyOwner {
    onSale = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function addWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i=0; i < _users.length; i++) {
      whitelistedAddresses.push(_users[i]);
    }
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

    /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
      override 
      virtual
      public
      view
      returns (bool)
  {
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }

  /**
   * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
   */
  function _msgSender()
      internal
      override
      view
      returns (address sender)
  {
      return ContextMixin.msgSender();
  }
}
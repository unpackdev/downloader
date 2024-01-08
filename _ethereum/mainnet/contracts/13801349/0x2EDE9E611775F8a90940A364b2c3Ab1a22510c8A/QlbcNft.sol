// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./console.sol";

contract QlbcNft is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public costPublic = 0.16 ether;
  uint256 public costVIP = 0.08 ether;
  uint256 public costPremium = 0.10 ether;
  uint256 public maxSupply = 10000;

  // Max number of NFTs that can be minted at one time
  uint256 public maxMintAmount = 20;

  // Max number of NFTs that can be minted at one time during a VIP Sale
  uint256 public vipMaxMintAmount = 5;

  // Max number of NFTs that can be minted at one time during a Premium Sale
  uint256 public premiumMaxMintAmount = 5;

  // max number of NFTs a VIP whitelist can mint
  uint256 public vipNftPerAddressLimit = 20;
  
  // max number of NFTs a Premium whitelist can mint
  uint256 public premiumNftPerAddressLimit = 20; 

  bool public paused = true;
  bool public revealed = false;

  // Only the VIP whitelisted users can mint if true
  bool public onlyVIPWhitelisted = true;

  // Only the Premium whitelisted users can mint if true
  bool public onlyPremiumWhitelisted = false;

  string public notRevealedUri;
  
  // List of addresses allowed to mint during VIP presale
  address[] public vipWhitelistedAddresses;

  // List of addresses allowed to mint during Premium presale
  address[] public premiumWhitelistedAddresses;

  mapping(address => uint256) public vipAddressMintedBalance;
  mapping(address => uint256) public premiumAddressMintedBalance;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    if(onlyVIPWhitelisted == true) {
      require(_mintAmount <= vipMaxMintAmount, "max mint amount per session exceeded");
    }
    if(onlyPremiumWhitelisted == true) {
      require(_mintAmount <= premiumMaxMintAmount, "max mint amount per session exceeded");
    }
    if(onlyVIPWhitelisted == false && onlyPremiumWhitelisted == false) {
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    }
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      if(onlyVIPWhitelisted == true) {
        require(isVIPWhitelisted(msg.sender), "user is not whitelisted");
        uint256 ownerMintedCount = vipAddressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= vipNftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= costVIP * _mintAmount);
      }
      else if(onlyPremiumWhitelisted == true) {
        require(isPremiumWhitelisted(msg.sender), "user is not whitelisted");
        uint256 ownerMintedCount = premiumAddressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= premiumNftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= costPremium * _mintAmount);
      }

      if (onlyVIPWhitelisted == false && onlyPremiumWhitelisted == false) {
        require(msg.value >= costPublic * _mintAmount);
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      if(onlyVIPWhitelisted == true) {
        vipAddressMintedBalance[msg.sender]++;
      }
      else if(onlyPremiumWhitelisted == true) {
        premiumAddressMintedBalance[msg.sender]++;
      }
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isVIPWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < vipWhitelistedAddresses.length; i++) {
      if (vipWhitelistedAddresses[i] == _user) {
        return true;
      }
    }
  
    return false;
  }

  function isPremiumWhitelisted(address _user) public view returns (bool) {
    
    for (uint i = 0; i < premiumWhitelistedAddresses.length; i++) {
      if (premiumWhitelistedAddresses[i] == _user) {
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
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
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

  function setVIPNftPerAddressLimit(uint256 _limit) public onlyOwner {
    vipNftPerAddressLimit = _limit;
  }

  function setPremiumNftPerAddressLimit(uint256 _limit) public onlyOwner {
    premiumNftPerAddressLimit = _limit;
  }
  
  function setPublicCost(uint256 _newCost) public onlyOwner {
    costPublic = _newCost;
  }

  function setPremiumCost(uint256 _newCost) public onlyOwner {
    costPremium = _newCost;
  }

  function setVIPCost(uint256 _newCost) public onlyOwner {
    costVIP = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setmaxVIPMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    vipMaxMintAmount = _newmaxMintAmount;
  }

  function setmaxPremiumMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    premiumMaxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
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

  function setOnlyVIPWhitelisted(bool _state) public onlyOwner {
    onlyVIPWhitelisted = _state;
    if (_state == true) {
      onlyPremiumWhitelisted = false;
    }
  }

  function setOnlyPremiumWhitelisted(bool _state) public onlyOwner {
    onlyPremiumWhitelisted = _state;
    if (_state == true) {
      onlyVIPWhitelisted = false;
    }
  }

  function setAllowPublicMinting() public onlyOwner {
    onlyPremiumWhitelisted = false;
    onlyVIPWhitelisted = false;
  }
  
  function whitelistVIPUsers(address[] calldata _users) public onlyOwner {
    delete vipWhitelistedAddresses;
    vipWhitelistedAddresses = _users;
  }

  function whitelistPremiumUsers(address[] calldata _users) public onlyOwner {
    delete premiumWhitelistedAddresses;
    premiumWhitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
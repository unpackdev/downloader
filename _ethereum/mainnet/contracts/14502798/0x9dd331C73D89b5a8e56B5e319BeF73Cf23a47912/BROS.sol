// SPDX-License-Identifier: GPL-3.0

//                                                              ZZZZ
//                                                           ZZZZZ
//                      ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
//                   ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
//                                              ZZZZZZZZZ
//                                           ZZZZZZZZ
//                                     ZZZZZZZZZZ
//                        ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
//                               ZZZZZZZZZ
//                           ZZZZZZZZ
//                       ZZZZZZZZZZ
//        ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
//   ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
//             ZZZZZZZ
//         ZZZZZZ

/**
 * BUFFALO BROS ENTERTAINMENT
 * BUFFALO BROS, LLC © 2022.
 * OKLAHOMA, USA.
 * https://buffalobros.io
 */

pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract BUFFALO_BROS_ENTERTAINMENT is ERC721EnumerableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  bool private initialized;

  string public baseURI;
  string public baseExtension;
  string public notRevealedUri;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  uint256 public nftPerAddressLimit;
  bool public paused;
  bool public revealed;
  bool public onlyWhitelisted;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

    function initialize(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri) 
    initializer public {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    cost = 0.1 ether;
    maxSupply = 10000;
    maxMintAmount = 10;
    nftPerAddressLimit =10;
    paused = false;
    revealed = false;
    onlyWhitelisted = true;
    baseExtension = "";
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
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
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
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    // This will pay 15% of the initial sale.
    // =============================================================================
    (bool hs, ) = payable(0xc1E8d5E04c22b15Dc9321C94c92bd743fFcc0518).call{value: address(this).balance * 15 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 85% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
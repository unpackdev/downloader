// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BuriedLoot is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "ipfs://QmWCWUhjg2n67GFH1LW2bJLb6jBNjkUQEa2xppM931M5Uo/";
  string public baseExtension = ".json";
  uint public cost = .05 ether;
  uint public maxSupply = 10000;
  uint public maxMintAmount = 10;
  uint public nftPerAddressLimit = 2;
  bool public paused = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  address payable public wal_jackpot = payable(0xac786c30899148612Fd6D7167f3ABB89DAED4DEb);
  address payable public wal_owners = payable(0xEd37083EaC50a78c9b8d32C1A8b11C58D656c460);
  address payable public wal_artist = payable(0x8147c04cb5c13b482820064e2BdD8A41Ab9A4B51);
  address payable public wal_web = payable(0x22438B6e5732d0827Dd95Fb5762B93B721001380);
  address payable public wal_block = payable(0xefF1b5a4643eAC7d0e908a83A3Cd9fC936990c00);
  


  constructor() ERC721("Buried Loot: Skull & Bones", "BRLT") {
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
  
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

  //only owner
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
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
    uint256 balance = address(this).balance;
    require(balance > 0);
    (bool jackpot_paid, ) = wal_jackpot.call{value: 50 * balance / 100}("");
    (bool owners_paid, ) = wal_owners.call{value: 25 * balance / 100}("");
    (bool artist_paid, ) = wal_artist.call{value: 5 * balance / 100}("");
    (bool webdev_paid, ) = wal_web.call{value: 10 * balance / 100}("");
    (bool blockdev_paid, ) = wal_block.call{value: 10 * balance / 100}("");
    require(jackpot_paid);
    require(owners_paid);
    require(artist_paid);
    require(webdev_paid);
    require(blockdev_paid);
  }
  
  function mintGiveaway(uint256 _giveawayAmount) public onlyOwner {
    for (uint256 i = 0; i < _giveawayAmount; ++i) {
        _safeMint(wal_owners, totalSupply());
    }
  }
  
}
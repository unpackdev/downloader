// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BrazuCat is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "https://brazucat.com/";
  string public baseExtension = ".json";
  string public notRevealedUri = "ipfs://QmbgcNj2ihyDaE2ZSrrkDX8dentd5JVYgy2wuvCMtKJfV8/1.json";
  uint256 public cost = 0.03 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 44;
  uint256 public commissionPercentage = 6;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address payable commissions = payable(0xd9c681F4c61B8E5B8Aed276458C7b6f3E14ea318);
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  address payable public payments;

  constructor(
    string memory _name,
    string memory _symbol,
    address _payments
  ) ERC721(_name, _symbol) {
    payments = payable(_payments);
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
    
    (bool success, ) = payable(commissions).call{value: msg.value * commissionPercentage / 100}("");
    require(success);
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
  function reveal() public onlyOwner() {
      revealed = true;
  }

  function setCommissionPercentage(uint256 _value) public onlyOwner() {
    commissionPercentage = _value;
  }

  function setComissionsAddress(address _address) public onlyOwner() {
    commissions = payable(_address);
  }

  function setPaymentAddress(address _address) public onlyOwner() {
    payments = payable(_address);
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
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
    (bool success, ) = payable(payments).call{value: address(this).balance}("");
    require(success);
  }
}

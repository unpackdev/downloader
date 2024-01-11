// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MutantTurtles is ERC721, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Minting {
    uint state;
    uint minimumFundsForWhitelistVerification; // in WEI
    uint price;
    uint whitelistPrice;
    uint8 defaultWhitelistAllowance;
  }

  event WhitelistVerified(string userDiscordId, address userAddress, bool enoughFunds);
  
  bool public verificationEnabled;
  
  bool public revealed;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;

  uint public maxSupply = 1978;
  Minting public minting;
  
  mapping(address => uint8) public whitelistAllowances;
  mapping(address => uint8) public airdropAllowance;

  Counters.Counter private _tokenId;

  constructor() ERC721("Mutant Turtles Club", "MTC") {}
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function mint(uint _mintAmount) public payable {
    require(minting.state != 0, "Minting is not active");
    require(_tokenId.current() + _mintAmount <= maxSupply, "Maximum minting limit reached");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    
    if (minting.state == 1) {
      require(whitelistAllowances[msg.sender] != 0, "Only whitelisted users allowed during presale");
      require(whitelistAllowances[msg.sender] != 255, "You have minted the maximum allowed during presale");
      require((whitelistAllowances[msg.sender] - _mintAmount) >= 0, "You have minted the maximum allowed during presale");
      
      require(msg.value >= minting.whitelistPrice * _mintAmount, "Please send the correct amount of ETH");
    }
    
    if (minting.state == 2) {
      require(msg.value >= minting.price * _mintAmount, "Please send the correct amount of ETH");
    }

    for (uint i = 0; i < _mintAmount; i++) {
      if (minting.state == 1) {
        whitelistAllowances[msg.sender] -= 1;
        
        if (whitelistAllowances[msg.sender] == 0) {
          whitelistAllowances[msg.sender] = 255; // 255 to indicate that we have no allowances, but differentiate from 0 which is default value.
        }
      }

      _tokenId.increment();
      _safeMint(msg.sender, _tokenId.current());
    }
  }

  function gift(address _to, uint _amount) public onlyOwner {
    require(_tokenId.current() + _amount <= maxSupply, "Maximum minting limit reached");

    for (uint i = 0; i < _amount; i++) {
      _tokenId.increment();
      _safeMint(_to, _tokenId.current());
    }
  }

  function claimAirdrop() public {
    uint _allowance = airdropAllowance[msg.sender];
    
    require(_allowance > 0, "You have no airdrops to claim");
    require(_tokenId.current() + _allowance <= maxSupply, "Max supply exceeded");
    
    for (uint i = 0; i < _allowance; i++) {
      _tokenId.increment();
      _safeMint(msg.sender, _tokenId.current());
    }
    
    airdropAllowance[msg.sender] = 0;
  }

  function burnSingleToken(uint tokenId) public onlyOwner {
    _burn(tokenId);
  }

  function burnMultipleTokens(uint _amount) public onlyOwner {
    require(_tokenId.current() + _amount <= maxSupply, "Maximum minting limit reached");

    for (uint i = 0; i < _amount; i++) {
      _tokenId.increment();
      _safeMint(msg.sender, _tokenId.current());
      _burn(_tokenId.current());
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");
    
    if (!revealed) {
        return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();    
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
  }

  function verifyForWhitelist(string memory userDiscordId) public {
    require(verificationEnabled, "Whitelist verification is not available yet");
    
    // Note that 0 is default value, and 255 is when all allowances have been used up
    require(whitelistAllowances[msg.sender] == 0, "You're already verified for whitelist");
    
    bool enoughFunds = msg.sender.balance >= minting.minimumFundsForWhitelistVerification;
    
    if (enoughFunds) {
      whitelistAllowances[msg.sender] = minting.defaultWhitelistAllowance;
    }
  
    emit WhitelistVerified(userDiscordId, msg.sender, enoughFunds);
  }
  
  function totalSupply() public view returns(uint) {
    return _tokenId.current();
  }

  function setMintingState(uint _state, uint _minimumFundsForWhitelistVerification, uint _price, uint _whitelistPrice, uint8 _defaultWhitelistAllowance) public onlyOwner {
    minting.state = _state;
    minting.minimumFundsForWhitelistVerification = _minimumFundsForWhitelistVerification;
    minting.price = _price;
    minting.whitelistPrice = _whitelistPrice;
    minting.defaultWhitelistAllowance = _defaultWhitelistAllowance;
  } 

  function deleteWhitelistAllowance(address[] memory _users) public onlyOwner {
     for (uint i = 0; i < _users.length; i++) {
          whitelistAllowances[_users[i]] = 0;
     }
  }

  function updateWhitelistAllowances(address[] memory _users, uint8[] memory _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      
      for (uint i = 0; i < _users.length; i++) {
          whitelistAllowances[_users[i]] = _allowances[i];
      }
  }

  function incrementWhitelistAllowancesBy(address[] memory _users, uint8 _amount) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          whitelistAllowances[_users[i]] = whitelistAllowances[_users[i]] + _amount;
      }
  }

  function setWhitelistAllowance(address _user, uint8 _amount) public onlyOwner {
    whitelistAllowances[_user] = _amount;
  }

  function setAirdropAllowance(address[] memory _users, uint8[] memory _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      
      for (uint i = 0; i < _users.length; i++) {
          airdropAllowance[_users[i]] = _allowances[i];
      }
  }

  function setVerificationEnabled(bool _verificationEnabled) public onlyOwner() {
      verificationEnabled = _verificationEnabled;
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function noopV1() public view returns(uint) {
    return _tokenId.current() + 1;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

}
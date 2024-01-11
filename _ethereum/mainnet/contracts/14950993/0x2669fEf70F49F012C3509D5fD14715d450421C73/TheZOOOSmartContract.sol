// SPDX-License-Identifier: MIT
/*
  _____   _                         ____    ___     ___     ___   
 |_   _| | |_      ___      o O O  |_  /   / _ \   / _ \   / _ \  
   | |   | ' \    / -_)    o        / /   | (_) | | (_) | | (_) | 
  _|_|_  |_||_|   \___|   TS__[O]  /___|   \___/   \___/   \___/  
_|"""""|_|"""""|_|"""""| {======|_|"""""|_|"""""|_|"""""|_|"""""| 
"`-0-0-'"`-0-0-'"`-0-0-'./o--000'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 
*/
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TheZOOOSmartContract is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  string public uriPrefix;
  string public uriSuffix = '.json';

  uint256 public publicMintCost = 0 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxPublicSupply = 9000;
  uint256 public maxPublicMintAmount = 5;
  uint256 public maxTeamSupply = maxSupply - maxPublicSupply;
  uint256 private currentTeamSupply = 0;

  bool public paused = false;
  // public mint balance
  mapping(address => uint256) public holderAddressPublicMintBalance;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
  }

  modifier publicMintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, 'Mint amount should be great than 0!');
    uint256 ownerMintedCount = holderAddressPublicMintBalance[msg.sender];
    require(
      _mintAmount + ownerMintedCount <= maxPublicMintAmount,
      'Max public NFT limit exceeded'
    );
    require(
      totalSupply() - currentTeamSupply + _mintAmount <= maxPublicSupply,
      'Max public supply exceeded!'
    );
    require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mintForTeam(uint256 _mintAmount, address _receiver)
    public
    onlyOwner
  {
    require(
      currentTeamSupply + _mintAmount <= maxTeamSupply,
      'Max supply exceeded for team members!'
    );
    currentTeamSupply += _mintAmount;
    _safeMint(_receiver, _mintAmount);
  }

  function publicMint(uint256 _mintAmount)
    public
    payable
    publicMintCompliance(_mintAmount)
  {
    require(!paused, 'Public mint not start');
    holderAddressPublicMintBalance[msg.sender] =
      _mintAmount +
      holderAddressPublicMintBalance[msg.sender];
    _safeMint(_msgSender(), _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
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
      'ERC721Metadata: URI query for nonexistent token'
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)
        )
        : '';
  }

  function setMaxSupply(uint256 _amount) public onlyOwner {
    maxSupply = _amount;
  }

  function setPublicMintCost(uint256 _cost) public onlyOwner {
    publicMintCost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMaxPublicMintAmount(uint256 _amount) public onlyOwner {
    require(_amount > 0, 'maxPublicMintAmount should be great than 0!');
    maxPublicMintAmount = _amount;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

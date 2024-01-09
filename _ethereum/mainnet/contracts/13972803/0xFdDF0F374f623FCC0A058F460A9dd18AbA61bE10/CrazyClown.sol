// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

import "./Counters.sol";
import "./Strings.sol";
import "./NFTExtension.sol";
import "./Metadata.sol";
import "./INFTStaking.sol";

contract CrazyClown is Metadata, NFTExtension {
  using Counters for Counters.Counter;
  using Strings for uint256;

  // Counter service to determine tokenId
  Counters.Counter private _tokenIds;

  // General details
  uint256 public constant maxSupply = 9696;

  // Public sale details
  uint256 public price = 0.05 ether; // Public sale price
  uint256 public publicSaleTransLimit = 10; // Public sale limit per transaction
  uint256 public publicMintLimit = 500; // Public mint limit per Wallet
  bool private _publicSaleStarted; // Flag to enable public sale
  mapping(address => uint256) public mintListPurchases;

  // Presale sale details
  uint256 public preSalePrice = 0.04 ether;
  uint256 public preSaleMintLimit = 10; // Presale limit per wallet
  bool public preSaleLive = false;
  Counters.Counter private preSaleAmountMinted;
  mapping(address => uint256) public preSaleListPurchases;
  mapping(address => bool) public preSaleWhitelist;

  // Reserve details for founders / gifts
  uint256 private reservedSupply = 196;

  // Metadata details
  string _baseTokenURI;
  string _contractURI;

  //NFTStaking interface
  INFTStaking public nftStaking;

  // Whitelist contracts
  address[] contractWhitelist;
  mapping(address => uint256) contractWhitelistIndex;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    string memory contractStoreURI,
    address utilityToken,
    address _proxyRegistryAddress
  ) ERC721(name, symbol) Metadata(utilityToken, maxSupply) {
    _publicSaleStarted = false;
    _baseTokenURI = baseURI;
    _contractURI = contractStoreURI;
    admins[_msgSender()] = true;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  // Public sale functions
  modifier whenPublicSaleStarted() {
    require(_publicSaleStarted, 'Sale has not yet started');
    _;
  }

  function flipPublicSaleStarted() external onlyOwner {
    _publicSaleStarted = !_publicSaleStarted;
  }

  function saleStarted() public view returns (bool) {
    return _publicSaleStarted;
  }

  function mint(uint256 _nbTokens, bool allowStaking) external payable override {
    // Presale minting
    require(_publicSaleStarted || preSaleLive, 'Sale has not yet started');
    uint256 _currentSupply = _tokenIds.current();
    if (!_publicSaleStarted && preSaleLive) {
      require(preSaleWhitelist[msg.sender] || isWhitelistContractHolder(msg.sender), 'Not on presale whitelist');
      require(preSaleListPurchases[msg.sender] + _nbTokens <= preSaleMintLimit, 'Exceeded presale allowed buy limit');
      require(preSalePrice * _nbTokens <= msg.value, 'Insufficient ETH');
      for (uint256 i = 0; i < _nbTokens; i++) {
        preSaleAmountMinted.increment();
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        preSaleListPurchases[msg.sender]++;
        tokenMintDate[newItemId] = block.timestamp;
        _safeMint(msg.sender, newItemId);
        if (allowStaking) {
          nftStaking.stake(address(this), newItemId, msg.sender);
        }
      }
    } else if (_publicSaleStarted) {
      // Public sale minting
      require(_nbTokens <= publicSaleTransLimit, 'You cannot mint that many NFTs at once');
      require(_currentSupply + _nbTokens <= maxSupply - reservedSupply, 'Not enough Tokens left.');
      require(mintListPurchases[msg.sender] + _nbTokens <= publicMintLimit, 'Exceeded sale allowed buy limit');
      require(_nbTokens * price <= msg.value, 'Insufficient ETH');
      for (uint256 i; i < _nbTokens; i++) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        mintListPurchases[msg.sender]++;
        tokenMintDate[newItemId] = block.timestamp;
        _safeMint(msg.sender, newItemId);
        if (allowStaking) {
          setApprovalForAll(address(nftStaking), true);
          nftStaking.stake(address(this), newItemId, msg.sender);
        }
      }
    }
  }

  /**
   * called after deployment so that the contract can get NFT staking contracts
   * @param _nftStaking the address of the NFTStaking
   */
  function setNFTStaking(address _nftStaking) external onlyOwner {
    nftStaking = INFTStaking(_nftStaking);
  }

  function setPublicMintLimit(uint256 limit) external onlyOwner {
    publicMintLimit = limit;
  }

  function setPublicSaleTransLimit(uint256 limit) external onlyOwner {
    publicSaleTransLimit = limit;
  }

  // Make it possible to change the price: just in case
  function setPrice(uint256 _newPrice) external onlyOwner {
    price = _newPrice;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  // Pre sale functions
  modifier whenPreSaleLive() {
    require(preSaleLive, 'Presale has not yet started');
    _;
  }

  modifier whenPreSaleNotLive() {
    require(!preSaleLive, 'Presale has already started');
    _;
  }

  function setPreSalePrice(uint256 _newPreSalePrice) external onlyOwner whenPreSaleNotLive {
    preSalePrice = _newPreSalePrice;
  }

  // Add an array of wallet addresses to the presale white list
  function addToPreSaleList(address[] calldata entries) external onlyOwner {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      require(entry != address(0), 'NULL_ADDRESS');
      require(!preSaleWhitelist[entry], 'DUPLICATE_ENTRY');

      preSaleWhitelist[entry] = true;
    }
  }

  // Remove an array of wallet addresses to the presale white list
  function removeFromPreSaleList(address[] calldata entries) external onlyOwner {
    for (uint256 i = 0; i < entries.length; i++) {
      address entry = entries[i];
      require(entry != address(0), 'NULL_ADDRESS');
      preSaleWhitelist[entry] = false;
    }
  }

  function isPreSaleApproved(address addr) external view returns (bool) {
    return preSaleWhitelist[addr];
  }

  function flipPreSaleStatus() external onlyOwner {
    preSaleLive = !preSaleLive;
  }

  function getPreSalePrice() public view returns (uint256) {
    return preSalePrice;
  }

  function setPreSaleMintLimit(uint256 _newPresaleMintLimit) external onlyOwner {
    preSaleMintLimit = _newPresaleMintLimit;
  }

  // Reserve functions
  // Owner to send reserve NFT to address
  function sendReserve(address _receiver, uint256 _nbTokens) public onlyAdmin {
    uint256 _currentSupply = _tokenIds.current();
    require(_currentSupply + _nbTokens <= maxSupply - reservedSupply, 'Not enough supply left');
    require(_nbTokens <= reservedSupply, 'That would exceed the max reserved');
    for (uint256 i; i < _nbTokens; i++) {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      tokenMintDate[newItemId] = block.timestamp;
      _safeMint(_receiver, newItemId);
    }
    reservedSupply = reservedSupply - _nbTokens;
  }

  function getReservedLeft() public view whenPublicSaleStarted returns (uint256) {
    return reservedSupply;
  }

  // Make it possible to change the reserve only if sale not started: just in case
  function setReservedSupply(uint256 _newReservedSupply) external onlyOwner {
    reservedSupply = _newReservedSupply;
  }

  // Storefront metadata
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _URI) external onlyOwner {
    _contractURI = _URI;
  }

  function setBaseURI(string memory _URI) external onlyOwner {
    _baseTokenURI = _URI;
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return _baseTokenURI;
  }

  // General functions & helper functions
  // Helper to list all the NFTs of a wallet
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw(address _receiver) public onlyOwner {
    uint256 _balance = address(this).balance;

    require(payable(_receiver).send(_balance));
  }

  function burn(uint256 tokenId) external override onlyAdmin {
    _burn(tokenId);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  }

  function addContractToWhitelist(address _contract) external onlyOwner {
    contractWhitelist.push(_contract);
    contractWhitelistIndex[_contract] = contractWhitelist.length - 1;
  }

  function removeContractFromWhitelist(address _contract) external onlyOwner {
    uint256 lastIndex = contractWhitelist.length - 1;
    address lastContract = contractWhitelist[lastIndex];
    uint256 contractIndex = contractWhitelistIndex[_contract];

    contractWhitelist[contractIndex] = lastContract;
    contractWhitelistIndex[lastContract] = contractIndex;
    if (contractWhitelist.length > 0) {
      contractWhitelist.pop();
      delete contractWhitelistIndex[_contract];
    }
  }

  function isWhitelistContractHolder(address user) internal view returns (bool) {
    for (uint256 index = 0; index < contractWhitelist.length; index++) {
      uint256 balanceOfSender = IERC721(contractWhitelist[index]).balanceOf(user);
      if (balanceOfSender > 0) return true;
    }
    return false;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId <= _tokenIds.current(), 'Token does not exist');
    if (PublicRevealStatus) return super.tokenURI(tokenId);
    else return placeHolderURI;
  }

  function isWhitelisted() public view returns (bool) {
    return (preSaleWhitelist[msg.sender] || isWhitelistContractHolder(msg.sender));
  }
}

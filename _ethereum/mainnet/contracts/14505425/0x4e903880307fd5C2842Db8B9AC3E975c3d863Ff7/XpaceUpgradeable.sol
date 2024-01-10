// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AddressUpgradeable.sol";


abstract contract WhitelistUpgradeable is OwnableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  bool private _soldWhitelist;
  bool internal _openWhitelist;

  mapping (uint => EnumerableSetUpgradeable.AddressSet) private _whitelist;

  event SellWhitelist(address account);
  event UnsellWhitelist(address account);

  function __WhiteList_init() internal onlyInitializing {
    __WhiteList_init_unchained();
  }

  function __WhiteList_init_unchained() internal onlyInitializing {
    _soldWhitelist = true;
    _openWhitelist = false;
  }

  modifier whenNotSold() {
    require(!sellWhitelist(), "Whitelist: sold");
    _;
  }

  modifier whenSold() {
    require(sellWhitelist(), "Whitelist: not sold");
    _;
  }

  function addWhitelist(uint key, address[] calldata accounts) public onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      _whitelist[key].add(accounts[i]);
    }
  }

  function removeWhitelist(uint key, address[] calldata accounts) public onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      _whitelist[key].remove(accounts[i]);
    }
  }

  function setOpenWhitelist(bool _open) public onlyOwner {
    _openWhitelist = _open;
  }

  function containsWhitelist(uint key, address account) public view returns (bool) {
    return _openWhitelist ? _whitelist[key].contains(account) : true;
  }

  function whitelist(uint key) public view returns (address[] memory) {
    return _whitelist[key].values();
  }

  function whitelistCount(uint key) public view returns (uint) {
    return _whitelist[key].length();
  }

  function sellWhitelist() public view returns (bool) {
    return _soldWhitelist;
  }

  function _sellWhitelist() internal whenNotSold {
    _soldWhitelist = true;
    emit SellWhitelist(_msgSender());
  }

  function _unsellWhitelist() internal whenSold {
    _soldWhitelist = false;
    emit UnsellWhitelist(_msgSender());
  }
}


abstract contract RevealableUpgradeable is ContextUpgradeable {
  bool private _revealed;

  event Revealed(address account);
  event Unrevealed(address account);

  function __Revealable_init() internal onlyInitializing {
    __Revealable_init_unchained();
  }

  function __Revealable_init_unchained() internal onlyInitializing {
    _revealed = false;
  }

  modifier whenNotRevealed() {
    require(!revealed(), "Revealable: revealed");
    _;
  }

  modifier whenRevealed() {
    require(revealed(), "Revealable: not revealed");
    _;
  }

  function revealed() public view returns (bool) {
    return _revealed;
  }

  function _reveal() internal whenNotRevealed {
    _revealed = true;
    emit Revealed(_msgSender());
  }

  function _unreveal() internal whenRevealed {
    _revealed = false;
    emit Unrevealed(_msgSender());
  }
}


contract XpaceUpgradeable is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, RevealableUpgradeable, WhitelistUpgradeable {
  using SafeMathUpgradeable for uint;
  using StringsUpgradeable for uint;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter private _nextTokenId;

  uint private _maxSupply;
  uint private _mintPrice;
  uint private _maxMint;

  string private _baseTokenURI;
  string private _baseTokenURIExtension;
  string private _blindBoxURI;
  string private _contractURI;

  address private _recipient;

  mapping(uint => string) private _tokenURIs;
  mapping(address => uint) private _whitelistMinted;
  mapping(address => uint) private _accountMinted;

  event ContractURI(string uri);
  event BaseTokenURI(string uri);
  event BaseTokenURIExtension(string extension);
  event TokenURI(uint tokenId, string uri);
  event BlindBoxURI(string uri);
  event MaxSupply(uint count);
  event MintPrice(uint price);
  event MaxMint(uint count);
  event Recipient(address account);


  function initialize(string memory _name, string memory _symbol) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    __WhiteList_init();
    __Revealable_init();
    __Pausable_init();
    __Xpace_init();
  }

  function __Xpace_init() internal onlyInitializing {
    __Xpace_init_unchained();
  }

  function __Xpace_init_unchained() internal onlyInitializing {
    _nextTokenId.increment();
    _pause();
    _reveal();

    _baseTokenURIExtension = ".json";
    _maxSupply = 9999;
    _maxMint = 2;
    _mintPrice = 0.365 ether;
    _recipient = 0x2423A82f3D97C2b5F0C247BAD4DccD4491EF1A3b;
    _contractURI = "ipfs://QmUfRj9ehWrUAv1qXAgvYi7CfDQNNuWx2uLKTcRPGwWHy2";
    _baseTokenURI = "ipfs://QmWcHDuh7yGBsZ6v5eUWZ8zmVRi1vekbnEMcdZzGqSwRga/";
  }

  receive() external payable {}
  fallback() external payable {}

  function mint(uint quantity) public payable whenNotPaused {
    require(!sellWhitelist() || containsWhitelist(1, _msgSender()) || containsWhitelist(2, _msgSender()), "NFT: must whitelist account can be mint");
    require(quantity > 0, "NFT: quantity cannot be zero");
    require(_mintPrice > 0, "NFT: not set mint price");
    require(_mintPrice * quantity <= msg.value, "NFT: not enough ether sent");
    uint mintCount = canMintCount(_msgSender());
    require(quantity <= mintCount, "NFT: cannot mint more");
    require(_recipient != address(0), "NFT: recipient not set");

    for (uint i = 0; i < quantity; i++) {
      _mint(_msgSender());
    }

    AddressUpgradeable.sendValue(payable(_recipient), msg.value);
  }

  function mintTo(address[] memory accounts, uint quantity) public onlyOwner {
    require(quantity > 0, "NFT: quantity cannot be zero");
    require(accounts.length * quantity <= _maxSupply.sub(totalSupply()), "NFT: cannot mint more");

    for (uint i = 0; i < accounts.length; i++) {
      for (uint j = 0; j < quantity; j++) {
        uint tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(accounts[i], tokenId);
      }
    }
  }

  function blindBoxURI() public view returns (string memory) {
    return _blindBoxURI;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "NFT: URI query for nonexistent token");

    if (!revealed()) {
      return blindBoxURI();
    }

    string memory _tokenURI = _tokenURIs[tokenId];

    if (bytes(_tokenURI).length > 0 || bytes(_baseURI()).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(_baseURI(), tokenId.toString(), _baseTokenURIExtension));
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
    emit ContractURI(uri);
  }

  function setBaseTokenURI(string memory uri) public onlyOwner {
    _baseTokenURI = uri;
    emit BaseTokenURI(uri);
  }

  function setBaseTokenURIExtension(string memory extension) public onlyOwner {
    _baseTokenURIExtension = extension;
    emit BaseTokenURIExtension(extension);
  }

  function setTokenURI(uint tokenId, string memory uri) public onlyOwner {
    require(_exists(tokenId), "NFT: URI set of nonexistent token");
    _tokenURIs[tokenId] = uri;
    emit TokenURI(tokenId, uri);
  }

  function setBlindBoxURI(string memory uri) public onlyOwner {
    _blindBoxURI = uri;
    emit BlindBoxURI(uri);
  }

  function setMaxSupply(uint count) public onlyOwner {
    _maxSupply = count;
    emit MaxSupply(count);
  }

  function setMintPrice(uint price) public onlyOwner {
    _mintPrice = price;
    emit MintPrice(price);
  }

  function setMaxMint(uint count) public onlyOwner {
    _maxMint = count;
    emit MaxMint(count);
  }

  function setRecipient(address account) public onlyOwner {
    require(_recipient != address(0), "NFT: recipient not zero address");
    _recipient = account;
    emit Recipient(account);
  }

  function flipRevealed() public onlyOwner {
    revealed() ? _unreveal() : _reveal();
  }

  function flipPaused() public onlyOwner {
    paused() ? _unpause() : _pause();
  }

  function flipSaleWhitelist() public onlyOwner {
    sellWhitelist() ? _unsellWhitelist() : _sellWhitelist();
  }

  function maxSupply() public view returns (uint) {
    return _maxSupply;
  }

  function mintPrice() public view returns (uint) {
    return _mintPrice;
  }

  function maxMint() public view returns (uint) {
    return _maxMint;
  }

  function whitelistMinted(address account) public view returns (uint) {
    return _whitelistMinted[account];
  }

  function accountMinted(address account) public view returns (uint) {
    return _accountMinted[account];
  }

  function canMintCount(address account) public view returns (uint) {
    uint minted;
    uint count;

    if (sellWhitelist()) {
      minted = _whitelistMinted[account];

      if (containsWhitelist(2, account)) {
        count = minted >= 2 ? 0 : uint(2).sub(minted);
      } else if (containsWhitelist(1, account)) {
        count = minted >= 1 ? 0 : uint(1).sub(minted);
      }
    } else {
      minted = _accountMinted[account];
      count = minted >= _maxMint ? 0 : _maxMint.sub(minted);
    }

    if (count > 0) {
      uint max = _maxSupply.sub(totalSupply());
      return max > count ? count : max;
    }

    return 0;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _mint(address to) internal {
    uint tokenId = _nextTokenId.current();
    _nextTokenId.increment();
    _safeMint(to, tokenId);

    if (sellWhitelist()) {
      _whitelistMinted[to] = _whitelistMinted[to].add(1);
    } else {
      _accountMinted[to] = _accountMinted[to].add(1);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ContextMixin.sol";
import "./ProxyRegistry.sol";
import "./NativeMetaTransaction.sol";
import "./VRFConsumerBaseUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract NFTImplementationV1_2 is
  VRFConsumerBaseUpgradeable,
  NativeMetaTransaction,
  OwnableUpgradeable,
  ContextMixin,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable
{
  using StringsUpgradeable for uint256;
  uint256 private constant UINT256_MAX = type(uint256).max - 1; // minus one so we can add 1 for randomness without overflow

  struct Sale {
    uint256 totalAmount;
    uint256 maxAmount;
    uint256 price;
    bool open;
  }

  mapping(address => bool) private _whitelist;
  mapping(address => uint256) private _airdropped;
  mapping(address => uint256) private _lastMint;
  address private _proxyRegistryAddress;
  bytes32 private _randomRequest;
  uint256 private _randomness;
  uint256 private _tokenId;

  bytes32 private _keyHash;
  uint256 private _fee;

  uint256 public maxSupply;
  uint256 public airdropAfter;
  uint256 public reserveMinted;
  uint256 public reserved;
  bool public revealed;
  Sale public presale;
  Sale public sale;

  event AirdropRequest(bytes32 requestId);
  event ToggleSale();

  function initialize(
    string memory name_,
    string memory symbol_,
    address proxyRegistryAddress_,
    address vrfCoordinatorAddress_,
    address linkAddress_,
    bytes32 keyHash_,
    uint256 fee_,
    uint256 reserved_,
    uint256 airdropAfter_,
    // [0: presaleTotal, 1: presaleMax, 2: presalePrice, 3: saleTotal, 4: saleMax, 5: salePrice]
    uint256[6] memory saleData_
  ) public initializer {
    __VRFConsumerBase_init(vrfCoordinatorAddress_, linkAddress_);
    __Ownable_init();
    __ERC165_init_unchained();
    __ERC721_init_unchained(name_, symbol_);
    __ERC721Enumerable_init_unchained();
    __ERC721Burnable_init_unchained();
    _initializeEIP712(name_);

    _tokenId = 1;
    _proxyRegistryAddress = proxyRegistryAddress_;
    _keyHash = keyHash_;
    _fee = fee_;

    reserved = reserved_;
    airdropAfter = airdropAfter_;
    presale.totalAmount = saleData_[0] + 2; // Add 2 so we can check lt and start at idx 1
    presale.maxAmount = saleData_[1] + 1; // Add 1 so we can check lt
    presale.price = saleData_[2];

    sale.totalAmount = saleData_[3] + 2; // Add 2 so we can check lt and start at idx 1
    sale.maxAmount = saleData_[4] + 1; // Add 1 so we can check lt
    sale.price = saleData_[5];
    maxSupply = saleData_[3] + reserved_;
  }

  receive() external payable {}

  function withdraw() external {
    require(address(this).balance > 0, "Nothing to withdraw");
    AddressUpgradeable.sendValue(
      payable(address(0x333Aa5768Ce2De083efA7443980f1A4342F0140A)),
      (address(this).balance * 3) / 10
    );
    AddressUpgradeable.sendValue(
      payable(address(0x205280b55d6c18CF1AAbC9c3a4118e885C32dcFc)),
      address(this).balance
    );
  }

  function mintPresale(uint256 amount)
    external
    payable
    presaleAvailable(amount)
  {
    _mintTo(_msgSender(), amount);
  }

  function mint(uint256 amount) external payable saleAvailable(amount) {
    _mintTo(_msgSender(), amount);
  }

  function requestAirdrop() external returns (bytes32 randomRequest) {
    require(totalSupply() >= airdropAfter, "Airdrop not available yet!");
    require(_randomRequest == bytes32(0), "Airdrop request already sent");
    _randomRequest = randomRequest = requestRandomness(_keyHash, _fee);
    emit AirdropRequest(randomRequest);
  }

  function airdrop() external {
    uint256 top = maxSupply + 1;
    uint256 randomness = _randomness;
    require(_randomRequest != bytes32(0), "Request airdrop first!");
    require(randomness != 0, "Airdrop request hasn't finalized");
    require(!_exists(top), "Airdrop already fulfilled");

    uint256 airdropCount = airdropAfter;
    for (uint256 i = 0; i < 5; i++) {
      randomness = uint256(keccak256(abi.encode(randomness, i))) % airdropCount;
      address account;
      uint256 skip;
      while (
        !_exists(randomness + 1) ||
        _airdropped[account = ownerOf(randomness + 1)] > 0
      ) {
        randomness = (++skip + randomness) % airdropCount;
      }

      _mint(account, top + i);
      _airdropped[account]++;
    }
  }

  function reveal() external onlyOwner {
    require(!revealed, "Already revealed");
    revealed = true;
  }

  function setReserved(uint256 amount) external onlyOwner {
    require(amount < reserved, "Amount must be less than current reserve");
    reserved = amount;
  }

  function mintReserve(address to, uint256 amount) external onlyOwner {
    require(reserveMinted < reserved, "All reserve minted");
    require(
      reserveMinted + amount <= reserved,
      "Reserve too low to meet amount"
    );

    reserveMinted += amount;
    _mintTo(to, amount);
  }

  function togglePresale() external onlyOwner {
    presale.open = !presale.open;
    sale.open = false;
    emit ToggleSale();
  }

  function toggleSale() external onlyOwner {
    sale.open = !sale.open;
    presale.open = false;
    emit ToggleSale();
  }

  function setWhitelisted(address[] calldata accounts, bool whitelisted)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      _whitelist[accounts[i]] = whitelisted;
    }
  }

  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    virtual
    returns (
      // override
      address receiver,
      uint256 royaltyAmount
    )
  {
    receiver = address(this);
    royaltyAmount = (salePrice * 25) / 100;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    string memory baseURI = _baseURI();
    if (bytes(baseURI).length == 0) {
      return "";
    }

    if (!revealed) {
      return baseURI;
    }

    return string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      /*IERC165Upgradeable, */
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable
    )
    returns (bool)
  {
    return
      interfaceId == type(IERC2981Upgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address _owner, address operator)
    public
    view
    override
    returns (bool)
  {
    // Whitelist OpenSea Proxy.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, operator);
  }

  function _mintTo(address to, uint256 amount) internal {
    uint256 tokenId = _tokenId;
    uint256 nextTokenId = _tokenId = tokenId + amount;
    for (_tokenId = tokenId + amount; tokenId < nextTokenId; tokenId++) {
      _mint(to, tokenId);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return
      revealed
        ? "ipfs://QmQmxxuPJbfLcmpZKAxSCRbjsdPkA5Z9rEuez8LbuUiu5f/"
        : "ipfs://Qmat6R6nTnYW9BRnwUVWQrqbjgGH5xWAD3VfFbxLLSHfQM";
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    virtual
    override
  {
    require(_randomRequest == requestId, "Invalid random request");
    _randomness = (randomness % UINT256_MAX) + 1;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _msgSender() internal view override returns (address sender) {
    return ContextMixin.msgSender();
  }

  modifier presaleAvailable(uint256 amount) {
    Sale memory _presale = presale;
    require(_presale.open, "Presale not open");
    require(msg.value == _presale.price * amount, "Invalid ETH amount");
    require(_whitelist[_msgSender()], "You aren't whitelisted!");
    require(
      _tokenId + amount < _presale.totalAmount + reserveMinted &&
        balanceOf(_msgSender()) + amount < _presale.maxAmount,
      "Presale sold out, or you're trying to mint too much"
    );
    _;
  }

  modifier saleAvailable(uint256 amount) {
    Sale memory _sale = sale;
    require(_sale.open, "Sale not open");
    require(msg.value == _sale.price * amount, "Invalid ETH amount");
    require(
      block.number - _lastMint[tx.origin] != 0,
      "One mint call per transaction!"
    );
    require(
      _tokenId + amount < _sale.totalAmount + reserveMinted &&
        amount < _sale.maxAmount,
      "Sale sold out, or you're trying to mint too much"
    );
    _;
    _lastMint[tx.origin] = block.number;
  }
}

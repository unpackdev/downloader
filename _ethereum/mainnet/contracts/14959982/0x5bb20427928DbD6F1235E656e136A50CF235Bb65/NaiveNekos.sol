// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

error SaleNotStarted();
error SaleInProgress();
error IncorrectPaymentAmount();
error AccountNotWhitelisted();
error AmountExceedsSupply();
error WhitelistAlreadyMinted();
error AmountExceedsTransactionLimit();
error DelegatedContractCallsNotAllowed();

contract NaiveNekos is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 2000;
  uint256 private constant FAR_FUTURE = 0xFFFFFFFFF;
  uint256 public  MAX_MINTS_PER_TX = 4;

  uint256 private _presaleStart = FAR_FUTURE;
  uint256 private _publicSaleStart = FAR_FUTURE;
  uint256 private _salePrice = 0 ether;

  address private _verifier;
  // hard code
  string public uriPrefix = 'ipfs://QmPxoqJS9xwzZEESCtEECgSSxfKvxc84Fdjb5SWat1ZNmo/';
  string public uriSuffix = '.json';
  mapping(address => bool) private _mintedWhitelist;

  event PresaleStart(uint256 price, uint256 supplyRemaining);
  event PublicSaleStart(uint256 price, uint256 supplyRemaining);
  event SalePaused();

  constructor(address verifier) ERC721A("NaiveNekos", "NEKOS") {
    _verifier = verifier;
  }

  // PRESALE WHITELIST

  function isPresaleActive() public view returns (bool) {
    return block.timestamp > _presaleStart;
  }

  function getSalePrice() public view returns (uint256) {
    return _salePrice;
  }

  function presaleMint(bytes calldata sig) external payable nonReentrant onlyEOA {
    if (!isPresaleActive())              revert SaleNotStarted();
    if (!isWhitelisted(msg.sender, sig)) revert AccountNotWhitelisted();
    if (hasMintedPresale(msg.sender))    revert WhitelistAlreadyMinted();
    if (totalSupply() + 1 > MAX_SUPPLY - 100)  revert AmountExceedsSupply();
    if (getSalePrice() != msg.value)     revert IncorrectPaymentAmount();

    _mintedWhitelist[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  function hasMintedPresale(address account) public view returns (bool) {
    return _mintedWhitelist[account];
  }

  function isWhitelisted(address account, bytes calldata sig) internal view returns (bool) {
    return ECDSA.recover(keccak256(abi.encodePacked(account)).toEthSignedMessageHash(), sig) == _verifier;
  }

  // PUBLIC SALE

  function isPublicSaleActive() public view returns (bool) {
    return block.timestamp > _publicSaleStart;
  }

  function publicSaleMint(uint256 quantity) external payable nonReentrant onlyEOA {
    if (!isPublicSaleActive())                  revert SaleNotStarted();
    // Reserve last 100 to dev teams
    if (totalSupply() + quantity > MAX_SUPPLY - 100)  revert AmountExceedsSupply();
    if (getSalePrice() * quantity != msg.value) revert IncorrectPaymentAmount();
    if (quantity > MAX_MINTS_PER_TX)            revert AmountExceedsTransactionLimit();

    _safeMint(msg.sender, quantity);
  }

  // METADATA

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
        : '';
  }

  // WEBSITE HELPERS

  function tokensOf(address owner) public view returns (uint256[] memory){
    uint256 count = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](count);
    for (uint256 i; i < count; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  // OWNERS + HELPERS

  function startPresale(uint256 price) external onlyOwner {
    if (isPublicSaleActive()) revert SaleInProgress();

    _presaleStart = block.timestamp;
    _salePrice = price;

    emit PresaleStart(price, MAX_SUPPLY - totalSupply());
  }

  function startPublicSale(uint256 price) external onlyOwner {
    if (isPresaleActive()) revert SaleInProgress();

    _publicSaleStart = block.timestamp;
    _salePrice = price;

    emit PublicSaleStart(price, MAX_SUPPLY - totalSupply());
  }

  function pauseSale() external onlyOwner {
    _presaleStart = FAR_FUTURE;
    _publicSaleStart = FAR_FUTURE;

    emit SalePaused();
  }

  modifier onlyEOA() {
    if (tx.origin != msg.sender) revert DelegatedContractCallsNotAllowed();
    _;
  }

  function setSalePrice(uint256 price) external onlyOwner {
    _salePrice = price;
  }

  // Reserve mint by the team
  function reserveMint(uint256 quantity) external onlyOwner {
    if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();
    _safeMint(owner(), quantity);
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    MAX_MINTS_PER_TX = _maxMintAmountPerTx;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}
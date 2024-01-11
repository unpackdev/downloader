// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

contract Richieandfamous is ERC721A, ERC2981, Ownable, ReentrancyGuard {
  enum MintPhase {
    PreSale,
    Sale,
    PostSale
  }

  uint256 public constant RESERVES = 111;
  uint256 public constant MAX_SUPPLY = 5555;
  string private _baseTokenURI;
  string private _contractURI;
  address public _proxyRegistryAddress;
  address payable private immutable _wallet;
  MintPhase private _mintPhase = MintPhase.PreSale;

  constructor(
    string memory baseTokenURI_,
    string memory contractURI_,
    address payable wallet_,
    address proxyRegistryAddress_
  ) ERC721A("Richieandfamous", "RF") {
    _baseTokenURI = baseTokenURI_;
    _contractURI = contractURI_;
    _wallet = wallet_;
    _proxyRegistryAddress = proxyRegistryAddress_;
    _setDefaultRoyalty(wallet_, 1000);
  }

  //////////////////////////////////////////////////////////////////
  // CORE FUNCTIONS                                               //
  //////////////////////////////////////////////////////////////////

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setBaseURI(string memory baseTokenURI_) public onlyOwner {
    _baseTokenURI = baseTokenURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory tokenUri = super.tokenURI(tokenId);
    return bytes(tokenUri).length > 0 ? string(abi.encodePacked(tokenUri, ".json")) : "";
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  //////////////////////////////////////////////////////////////////
  // RESERVE TOKENS                                               //
  //////////////////////////////////////////////////////////////////

  function collectReserves() public onlyOwner {
    require(_mintPhase == MintPhase.PreSale, "Sale already open");
    require(totalSupply() == 0, "Reserves already collected");
    _mint(owner(), RESERVES);
  }

  //////////////////////////////////////////////////////////////////
  // SALE                                                         //
  //////////////////////////////////////////////////////////////////

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function canMint(address account) public view returns (bool) {
    return _numberMinted(account) == 0;
  }

  function setMintPhase(MintPhase phase) external onlyOwner {
    _mintPhase = phase;
  }

  function mintPhase() public view returns (MintPhase) {
    return _mintPhase;
  }

  function mint() public payable callerIsUser {
    require(_mintPhase == MintPhase.Sale, "Sale not open");
    require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
    require(canMint(_msgSender()), "Already minted");
    _mint(_msgSender(), 1);
  }

  //////////////////////////////////////////////////////////////////
  // POST SALE MANAGEMENT                                         //
  //////////////////////////////////////////////////////////////////

  function withdraw() public nonReentrant {
    _wallet.transfer(address(this).balance);
  }

  function wallet() public view returns (address) {
    return _wallet;
  }

  //////////////////////////////////////////////////////////////////
  // OpenSea                                                      //
  //////////////////////////////////////////////////////////////////

  function setOpenSeaProxyRegistryAddress(address proxyRegistryAddress_) external onlyOwner {
    _proxyRegistryAddress = proxyRegistryAddress_;
  }

  function isApprovedForAll(address _owner, address operator) public view virtual override returns (bool) {
    if (_proxyRegistryAddress != address(0)) {
      OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(_proxyRegistryAddress);
      if (address(proxyRegistry.proxies(_owner)) == operator) {
        return true;
      }
    }
    return super.isApprovedForAll(_owner, operator);
  }

  //////////////////////////////////////////////////////////////////
  // ERC165                                                       //
  //////////////////////////////////////////////////////////////////

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return interfaceId == type(Ownable).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

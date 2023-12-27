// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.14;

import "./AccessControl.sol";
import "./EIP712Common.sol";
import "./Toggleable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

error ExceedsMaxPerWallet();
error ExceedsMaxSupply();

contract MysterySneakerBox is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, AccessControl, Toggleable, EIP712Common{
  uint256 public MAX_PER_WALLET;
  uint256 public MAX_SUPPLY;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    uint256 _tokensForSale
  ) ERC721A(_tokenName, _tokenSymbol) {
    customBaseURI = _customBaseURI;

    MAX_SUPPLY = _tokensForSale;
    MAX_PER_WALLET = 3;
  }

  /** MINTING **/

  function mint(uint256 _count) external noContracts requireActiveSale {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);
  }

  function ownerMint(uint256 _count, address _recipient) external onlyOwner() {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();

    _mint(_recipient, _count);
  }

  function whitelistMint(uint256 _count, bytes calldata _signature) external requiresWhitelist(_signature) requireActiveWhitelist noContracts {
    if(_totalMinted() + _count > MAX_SUPPLY) revert ExceedsMaxSupply();
    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);
  }

  /** MINTING LIMITS **/

  function allowedMintCount(address minter) public view returns (uint256) {
    return MAX_PER_WALLET - _numberMinted(minter);
  }

  function setMaxPerWallet(uint256 _max) external onlyOwner() {
    MAX_PER_WALLET = _max;
  }

  /** WHITELIST **/

  function checkWhitelist(bytes calldata signature) public view requiresWhitelist(signature) returns (bool) {
    return true;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    return customBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}

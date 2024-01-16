// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

// import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";


import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

import "./ITrinviNFT.sol";

// import "./console.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
      mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title TrinviNFTV2
 * TrinviNFTV2 - ERC721 contract that is controlled by a Sale Contract for Minting.
 */
contract TrinviNFTV2 is ITrinviNFT, ERC721A, ContextMixin, NativeMetaTransaction, Ownable {
  // =============================================================
  //                            LIBRARIES
  // =============================================================
  using SafeMath for uint256;

  // =============================================================
  //                            ERRORS
  // =============================================================
  error AlreadyInitialized();
  error OnlySaleContract();

  // =============================================================
  //                            STORAGE
  // =============================================================
  address public _saleContractAddress;
  address public _proxyRegistryAddress;
  uint256 public _mintPrice;
  bool public _isRevealed;
  uint256 public _maxSupply;
  string public _contractURI;
  string private _baseTokenURI;
  string public _unrevealedTokenURI;
  bool public _isInitialized;


  // =============================================================
  //                            MAPPINGS
  // =============================================================
  mapping(uint256 => bool) public _isRevealedById;


  // =============================================================
  //                            MODIFIERS
  // =============================================================
  modifier _maxSupplyNotReached(uint qty) {
    require(_nextTokenId() + (qty) <= _maxSupply, "Cannot mint more than _maxSupply");
    _;
  }

  modifier onlySaleContract() {
    if (msg.sender != _saleContractAddress) {
      revert OnlySaleContract();
    }
    _;
  }


  constructor(
    string memory name,
    string memory symbol,
    string memory contractURIParam,
    string memory baseTokenURIParam,
    string memory unrevealedTokenURIParam,
    address proxyRegistryAddress,
    uint256 maxSupply
  ) ERC721A(name, symbol) {
    _proxyRegistryAddress = proxyRegistryAddress;
    _initializeEIP712(name);
    _maxSupply = maxSupply;
    _contractURI = contractURIParam;
    _baseTokenURI = baseTokenURIParam;
    _unrevealedTokenURI = unrevealedTokenURIParam;
  }

  function initialize(address saleContractAddress_) external override onlyOwner {
    if (_isInitialized) {
      revert AlreadyInitialized();
    }
    _saleContractAddress = saleContractAddress_;

    _isInitialized = true;
  }

  function isInitialized() external override view returns (bool) {
    return _isInitialized;
  }

  function saleContractAddress() external override view returns (address) {
    return _saleContractAddress;
  }

  function reveal() external onlyOwner returns (bool) {
    _isRevealed = true;
    return _isRevealed;
  }

  /**
    * @dev for demo purposes
    */
  function revealById(uint256 tokenId) external onlyOwner returns (bool) {
    _isRevealedById[tokenId] = true;
    return _isRevealedById[tokenId];
  }

  /**
    * @dev Mints a token to an address.
    * @param to address of the future owner of the token
    */
  function mintTo(address to, uint qty) external override onlySaleContract _maxSupplyNotReached(qty) {
    _safeMint(to, qty);
  }

  function setSaleContractAddress(address address_) external onlyOwner {
    _saleContractAddress = address_;
  }

  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function unrevealedTokenURI() public view returns (string memory) {
    return _unrevealedTokenURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    if (_isRevealedById[_tokenId]) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }
    if (!_isRevealed) {
        return unrevealedTokenURI();
    }
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /**
    * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    */
  function _msgSender()
    internal
    override
    view
    returns (address sender)
  {
    return ContextMixin.msgSender();
  }
}


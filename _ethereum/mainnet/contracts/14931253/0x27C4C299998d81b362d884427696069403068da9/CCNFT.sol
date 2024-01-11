// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2; // required to accept structs as function parameters

import "./AccessControl.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}


contract CCNFT is ERC721, ERC721URIStorage, ERC721Royalty, EIP712, Pausable, AccessControl, PullPayment {
  using Counters for Counters.Counter;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string private constant CONTRACT_NAME = "Claim Contest";
  string private constant CONTRACT_SYMBOL = "CCNFT";
  string private constant SIGNATURE_DOMAIN = "CCNFT";
  string private constant SIGNATURE_VERSION = "1";

  Counters.Counter private _mintCounter;
  Counters.Counter private _burnCounter;

  string private _baseUriValue = "https://api.claimcontest.com/v1/nft/";
  string private _contractUri = "https://api.claimcontest.com/v1/nft/contract";
  address private _proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea mainnet proxy

  mapping(string => uint256) private _tokenIdByURI;
  mapping(uint256 => bool) private _pausedByTokenId;

  event Minted(address owner, uint256 tokenId, string uri);
  event PausedToken(address account, uint256 tokenId);
  event UnpausedToken(address account, uint256 tokenId);

  constructor()
  ERC721(CONTRACT_NAME, CONTRACT_SYMBOL)
  EIP712(SIGNATURE_DOMAIN, SIGNATURE_VERSION) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    //2.5% ERC721Royalty
    _setDefaultRoyalty(msg.sender, 250);
  }

  /// @notice Mints nft to caller based on a voucher.
  /// @param voucher A signed Voucher that describes the NFT to be minted.
  function mint(Voucher calldata voucher) public payable returns (uint256) {
    // verify the voucher
    address signer = verifyVoucher(voucher);
    require(hasRole(MINTER_ROLE, signer), string(abi.encodePacked("Signature invalid or unauthorized.  signer:", Strings.toHexString(uint256(uint160(signer)), 20))));
    require(msg.value >= voucher.price, "Value less than mint price");
    require(voucher.redeemer != address(0), "Voucher redeemer not defined");
    require(block.timestamp < voucher.expiration, "Voucher expired");
    require(_tokenIdByURI[voucher.uri] == 0, "Voucher duplicate");

    _mintCounter.increment();
    uint256 tokenId = _mintCounter.current();
    address redeemer = voucher.redeemer;

    // mint
    _safeMint(redeemer, tokenId);
    _setTokenURI(tokenId, voucher.uri);

    // store PullPayment
    _asyncTransfer(signer, msg.value);

    _tokenIdByURI[voucher.uri] = tokenId;
    emit Minted(redeemer, tokenId, voucher.uri);
    return tokenId;
  }

  /// @notice Returns the number of minted tokens
  function getMintCount() public view returns (uint256) {
    return _mintCounter._value;
  }

  /// @notice Returns the number of burned tokens
  function getBurnCount() public view returns (uint256) {
    return _burnCounter._value;
  }

  /// @notice Returns the number of non-burned tokens
  function totalSupply() public view returns (uint256) {
    return _mintCounter._value - _burnCounter._value;
  }

  /// @notice Verifies the signature for a given Voucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An Voucher describing an unminted NFT.
  function verifyVoucher(Voucher calldata voucher) public view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  /// @notice Returns the chain id of the current blockchain.
  /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
  ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function contractURI() public view returns (string memory) {
    return _contractUri;
  }

  function tokenIdForURI(string memory uri) public view returns (uint256) {
    return _tokenIdByURI[uri];
  }

  function isPausedToken(uint256 tokenId) public view returns (bool)  {
    return _pausedByTokenId[tokenId];
  }

  ///////////////////// Admin

  function adminMint(address to, string memory uri) public onlyRole(MINTER_ROLE) returns (uint256) {
    _mintCounter.increment();
    uint256 tokenId = _mintCounter.current();

    // first assign the token to the minter to establish provenance on-chain
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, uri);
    _transfer(msg.sender, to, tokenId);

    _tokenIdByURI[uri] = tokenId;
    emit Minted(to, tokenId, uri);
    return tokenId;
  }

  function withdrawPayments(address payable payee) public virtual override(PullPayment) onlyRole(MINTER_ROLE) {
    super.withdrawPayments(payee);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function pauseToken(uint256 tokenId) public onlyRole(PAUSER_ROLE) {
    _pausedByTokenId[tokenId] = true;
    emit PausedToken(_msgSender(), tokenId);
  }

  function unpauseToken(uint256 tokenId) public onlyRole(PAUSER_ROLE) {
    if (_pausedByTokenId[tokenId]) {
      delete _pausedByTokenId[tokenId];
      emit UnpausedToken(_msgSender(), tokenId);
    }
  }

  function burn(uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _burn(tokenId);
  }

  function setContractURI(string memory uri) public onlyRole(MINTER_ROLE) {
    _contractUri = uri;
  }

  function setBaseURI(string memory baseUri) public onlyRole(MINTER_ROLE) {
    _baseUriValue = baseUri;
  }

  function setProxyRegistryAddress(address proxyRegistryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _proxyRegistryAddress = proxyRegistryAddress;
  }

  function getProxyRegistryAddress() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address)  {
    return _proxyRegistryAddress;
  }

  ///////////////////// Overrides

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused virtual override {
    require(!isPausedToken(tokenId), "Token paused");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage, ERC721Royalty) {
    string memory uri = tokenURI(tokenId);
    super._burn(tokenId);
    _burnCounter.increment();

    if (_tokenIdByURI[uri] != 0) {
      delete _tokenIdByURI[uri];
    }
    if (_pausedByTokenId[tokenId]) {
      delete _pausedByTokenId[tokenId];
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUriValue;
  }

  function _hashTypedDataV4(bytes32 structHash) internal view virtual override(EIP712) returns (bytes32) {
    return super._hashTypedDataV4(structHash);
  }

  function isApprovedForAll(address owner, address operator) virtual override public view returns (bool) {
    // Approve OpenSea proxy contract for easy gas-less listings.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  ///////////////////// Voucher

  /// @notice Represents a minting operation. A signed voucher can be redeemed for a real NFT by passing it to the public mint function.
  struct Voucher {
    /// @notice The metadata URI to associate with this token.
    string uri;
    /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 price;
    /// @notice The time in epoc seconds when this voucher becomes invalid
    uint256 expiration;
    /// @param redeemer The address of the account which will receive the NFT upon success.
    address redeemer;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }

  /// @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher A Voucher to hash.
  function _hash(Voucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Voucher(string uri,uint256 price,uint256 expiration,address redeemer)"),
        keccak256(bytes(voucher.uri)),
        voucher.price,
        voucher.expiration,
        voucher.redeemer
      )));
  }
}

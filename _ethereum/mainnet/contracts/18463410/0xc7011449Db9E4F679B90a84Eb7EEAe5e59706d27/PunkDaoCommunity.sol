// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICryptoPunksMarket.sol";
import "./IDelegateRegistry.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title PunkDaoCommunity
 * @author Arkaydeus @ Punk DAO
 * @notice The Punk DAO community membership token
 * Please visit https://punk-dao.xyz for more information.
 */

contract PunkDaoCommunity is ERC721, ERC721Enumerable, Ownable {
  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  enum SalePhase {
    Deployed,
    Live,
    Paused
  }

  event Minted(address indexed _from, uint256 indexed _tokenId);

  // Public variables
  SalePhase public salePhase = SalePhase.Deployed;
  uint256 public mintRate = 0.0 ether;

  // Private variables
  string public contractURI;
  address private immutable adminSigner;

  /// @notice CryptoPunksMarket contract address
  address public punkContractAddress;

  /// @notice Delegate.Cash contract address
  address public delegateCashAddress;

  constructor(
    string memory _contractURI,
    address _adminSigner,
    address _deployedPunkContractAddress,
    address _delegateCashAddress
  ) ERC721("Punk DAO Community Membership", "PUNKDC") {
    contractURI = _contractURI;
    adminSigner = _adminSigner;
    punkContractAddress = _deployedPunkContractAddress;
    delegateCashAddress = _delegateCashAddress;
  }

  // Advance Phase
  // @dev Advance the sale phase state
  // @notice Advances sale phase state incrementally
  function enterPhase(SalePhase _salePhase) external onlyOwner {
    require(_salePhase != SalePhase.Deployed, "Cannot set as deployed");
    salePhase = _salePhase;
  }

  /// Mint with coupon
  /// @dev mints by addresses validated using verified coupons signed by an admin signer
  /// @param _tokenId token ID of the cryptopunk to mint in relation to
  /// @param _to address to mint to
  function couponMint(
    uint256 _tokenId,
    address _to,
    Coupon memory _coupon
  ) external payable {
    // If token already exists, activate transfer to new owner
    if (_exists(_tokenId)) {
      require(
        checkValidToAddress(_tokenId, msg.sender),
        "Caller doesn't have authority to transfer token"
      );
      require(checkValidToAddress(_tokenId, _to), "Invalid to address");
      _transfer(_ownerOf(_tokenId), _to, _tokenId);
      return;
    }

    require(salePhase == SalePhase.Live, "Minting is not live");

    bytes32 payloadHash = keccak256(abi.encode(_tokenId, _to));
    bytes32 messageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
    );

    require(_isVerifiedCoupon(messageHash, _coupon), "Invalid coupon");

    require(
      checkValidToAddress(_tokenId, _to),
      "To address is not valid for tokenId."
    );
    require(
      msg.value == mintRate,
      "Transaction value did not equal mint price"
    );

    _safeMint(_to, _tokenId);
    emit Minted(_to, _tokenId);
  }

  /// Set contact URI
  /// @dev sets the URI for metadata
  /// @param _contractURI URI for contract metadata
  function setContractURI(string calldata _contractURI) external onlyOwner {
    contractURI = _contractURI;
  }

  /// Set mint rate
  /// @dev sets the mint rate for the contract
  /// @param _mintRate rate to mint at (price)
  function setMintRate(uint256 _mintRate) external onlyOwner {
    mintRate = _mintRate;
  }

  /// Is Verified Coupon
  /// @dev checks if a coupon is valid
  /// @param _digest digest of the coupon
  /// @param _coupon coupon to check
  function _isVerifiedCoupon(
    bytes32 _digest,
    Coupon memory _coupon
  ) internal view returns (bool) {
    address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
    require(signer != address(0), "ECDSA: invalid signature");

    return signer == adminSigner;
  }

  /// Is With Punk
  /// @dev checks if a token is with a punk
  /// @param _tokenId token ID to check
  function isWithPunk(uint256 _tokenId) public view returns (bool) {
    if (
      ICryptoPunksMarket(punkContractAddress).punkIndexToAddress(_tokenId) ==
      super.ownerOf(_tokenId)
    ) {
      return true;
    }

    if (isDelegatedByPunk(_tokenId)) {
      return true;
    }

    return false;
  }

  /// Is Delegated By Punk
  /// @dev checks if a caller is delegated by a punk address
  /// @param _tokenId token ID to check
  function isDelegatedByPunk(uint256 _tokenId) public view returns (bool) {
    return _checkDelegation(_tokenId, super.ownerOf(_tokenId));
  }

  /// Withdraw
  /// @dev withdraws ETH from the contract
  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "ETH withdrawal failed");
  }

  /// Check Delegation
  /// @dev checks if a delegate is valid for a token ID
  /// @param _tokenId token ID to check
  /// @param _delegate delegate address to check
  function _checkDelegation(
    uint256 _tokenId,
    address _delegate
  ) internal view returns (bool) {
    return
      IDelegateRegistry(delegateCashAddress).checkDelegateForERC721(
        _delegate,
        ICryptoPunksMarket(punkContractAddress).punkIndexToAddress(_tokenId),
        punkContractAddress,
        _tokenId,
        ""
      );
  }

  /// Check Valid To Address
  /// @dev checks if a to address is valid for a token ID
  /// @param _tokenId token ID to check
  /// @param _to to address to check
  function checkValidToAddress(
    uint256 _tokenId,
    address _to
  ) public view returns (bool) {
    return (_checkDelegation(_tokenId, _to) ||
      (ICryptoPunksMarket(punkContractAddress).punkIndexToAddress(_tokenId)) ==
      _to);
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) {
    require(checkValidToAddress(tokenId, to), "To address is not valid.");

    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function _burn(uint256 tokenId) internal override(ERC721) {
    super._burn(tokenId);
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return contractURI;
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//  ██▓    ▄▄▄      ▒███████▒ ▄▄▄       ██▀███   █    ██   ██████ 
// ▓██▒   ▒████▄    ▒ ▒ ▒ ▄▀░▒████▄    ▓██ ▒ ██▒ ██  ▓██▒▒██    ▒ 
// ▒██░   ▒██  ▀█▄  ░ ▒ ▄▀▒░ ▒██  ▀█▄  ▓██ ░▄█ ▒▓██  ▒██░░ ▓██▄   
// ▒██░   ░██▄▄▄▄██   ▄▀▒   ░░██▄▄▄▄██ ▒██▀▀█▄  ▓▓█  ░██░  ▒   ██▒
// ░██████▒▓█   ▓██▒▒███████▒ ▓█   ▓██▒░██▓ ▒██▒▒▒█████▓ ▒██████▒▒
// ░ ▒░▓  ░▒▒   ▓▒█░░▒▒ ▓░▒░▒ ▒▒   ▓▒█░░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░
// ░ ░ ▒  ░ ▒   ▒▒ ░░░▒ ▒ ░ ▒  ▒   ▒▒ ░  ░▒ ░ ▒░░░▒░ ░ ░ ░ ░▒  ░ ░
//   ░ ░    ░   ▒   ░ ░ ░ ░ ░  ░   ▒     ░░   ░  ░░░ ░ ░ ░  ░  ░  
//     ░  ░     ░  ░  ░ ░          ░  ░   ░        ░           ░  
//                  ░                                          

import "./ERC721.sol";
import "./Ownable.sol";

contract LazarusNFT is ERC721, Ownable {
  
  event ProvenanceHashSet(bytes32);

  uint16 public immutable TOTAL_SUPPLY;
  
  bool public whitelistSaleIsActive = false;
  bool public publicSaleIsActive = false;
  bytes32 public provenanceHash;

  uint16 private _mintIndex;
  bool private _isRevealed = false;
  string private _preRevealURI;
  string private _postRevealBaseURI;
  address private _couponSigner;
  mapping(address => bool) private _whitelistMinted;
  mapping(address => bool) private _publicMinted;

  enum CouponType {
    Mint
  }

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(string memory preRevealURI, bytes32 _provenanceHash, uint16 totalSupply) ERC721 ("Lazarus: Disciples", "LAZD") {
    _couponSigner = owner();
    _preRevealURI = preRevealURI;
    TOTAL_SUPPLY = totalSupply;
    setProvenanceHash(_provenanceHash);
  }

  // External functions

  function mint(Coupon memory coupon)
    external
  {
    // require that sale is active
    require(whitelistSaleIsActive, "Sale is not active.");

    // require that the TOTAL_SUPPLY has not been reached
    require(_mintIndex < TOTAL_SUPPLY, "Minting limit reached.");

    // require a valid coupon
    require(
      _isVerifiedCoupon(_createMessageDigest(CouponType.Mint, msg.sender), coupon), 
      "Coupon is not valid."
    );

    // require that each wallet can only mint one token
    require(
      !_whitelistMinted[msg.sender],
      "Wallet has already minted."
    );

    _whitelistMinted[msg.sender] = true;

    _safeMint(msg.sender, _mintIndex);

    _mintIndex++;
  }

  function publicMint()
    external
  {
    // require that sale is active
    require(publicSaleIsActive, "Sale is not active.");

    // require that the TOTAL_SUPPLY has not been reached
    require(_mintIndex < TOTAL_SUPPLY, "Minting limit reached.");

    // require that each wallet can only public mint one token
    require(
      !_publicMinted[msg.sender],
      "Wallet has already minted."
    );

    _publicMinted[msg.sender] = true;

    _safeMint(msg.sender, _mintIndex);

    _mintIndex++;
  }

  function setCouponSigner(address couponSigner)
    external
    onlyOwner
  {
    _couponSigner = couponSigner;
  }

  function setPreRevealURI(string memory preRevealURI)
    external
    onlyOwner
  {
    _preRevealURI = preRevealURI;
  }

  function reveal(string memory baseURI)
    external
    onlyOwner
  {
    _postRevealBaseURI = baseURI;
    _isRevealed = true;
  }

  function setWhitelistSaleState(bool _whitelistSaleIsActive)
    external
    onlyOwner
  {
    whitelistSaleIsActive = _whitelistSaleIsActive;
  }

  function setPublicSaleState(bool _publicSaleIsActive)
    external
    onlyOwner
  {
    publicSaleIsActive = _publicSaleIsActive;
  }

  function setProvenanceHash(bytes32 _provenanceHash)
    public
    onlyOwner
  {
    require(_mintIndex == 0, "Sale has started.");

    provenanceHash = _provenanceHash;

    emit ProvenanceHashSet(provenanceHash);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    if (!_isRevealed) {
      return _preRevealURI;
    }

    return super.tokenURI(tokenId);
  }

  /// @dev Override _baseURI
  function _baseURI()
    internal
    view
    override(ERC721) returns (string memory)
  {
    return _postRevealBaseURI;
  }

  /// @dev check that the coupon sent was signed by the coupon signer
  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
    internal
    view
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "ECDSA: invalid signature");
    return signer == _couponSigner;
  }

  function _createMessageDigest(CouponType _type, address _address)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(_type, _address))
      )
    );
  }
}
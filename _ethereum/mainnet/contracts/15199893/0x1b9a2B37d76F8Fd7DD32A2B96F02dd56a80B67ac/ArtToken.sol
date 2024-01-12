// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./PRBMathUD60x18.sol";
import "./RoyaltySplitter.sol";

contract ArtToken is AccessControlUpgradeable, ERC721Upgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable {

  string private baseTokenURI;

  bytes4 constant internal ERC1271_MAGICVALUE =
      bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  bytes32 constant internal EIP712_DOMAIN_TYPEHASH = keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  function eip712DomainSeparator() internal view returns (bytes32) {
    return keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes("MetaMural ArtToken")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)));
  }

  // This role has the ability to authorize new artists
  bytes32 private constant AUTHORIZER = keccak256("AUTHORIZER");
  bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
  // A valid gallery and artist signature must be provided to mint a new token
  bytes32 private constant GALLERY = keccak256("GALLERY");

  struct MintApproval {
    uint tokenId;
    uint price;
    // Platform and gallery fees should be expressed in ETH
    uint platformFee;
    uint galleryFee;
    // Royalty fee should be an 18-digit fixed-point number, 100% = 1 ether
    uint royaltyFee;
    address artistAddress;
    address galleryAddress;
    address royaltyAddress;
    // Additional fees are paid to these addresses
    uint[] additionalFees;
    address[] additionalAddresses;

    bytes platformSignature;
    bytes gallerySignature;
  }

  bytes32 constant internal MINT_APPROVAL_TYPEHASH = keccak256(
      "MintApproval(uint tokenId,uint price,uint platformFee,uint galleryFee,uint royaltyFee,address artistAddress,address galleryAddress,address royaltyAddress,uint[] additionalFees,address[] additionalAddresses)");

  function mintApprovalHash(MintApproval memory approval) public pure
      returns (bytes32) {
    return keccak256(abi.encode(
        MINT_APPROVAL_TYPEHASH,
        approval.tokenId,
        approval.price,
        approval.platformFee,
        approval.galleryFee,
        approval.royaltyFee,
        approval.artistAddress,
        approval.galleryAddress,
        approval.royaltyAddress,
        keccak256(abi.encodePacked(approval.additionalFees)),
        keccak256(abi.encodePacked(approval.additionalAddresses))));
  }

  struct RoyaltyInfo {
    address royaltyAddress;
    uint royaltyFee;
  }
  mapping(uint => RoyaltyInfo) royaltyData;

  function initialize() public initializer {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    ERC721Upgradeable.__ERC721_init("MetaMural Art", "MM");
    baseTokenURI = "https://metamural.io/token/";

    _setRoleAdmin(GALLERY, AUTHORIZER);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function mint(MintApproval calldata approval) external payable nonReentrant {
    require(!_exists(approval.tokenId), "mint: Token already exists");
    bytes32 hash = mintApprovalHash(approval);

    require(hasRole(GALLERY, ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toTypedDataHash(eip712DomainSeparator(), hash),
            approval.gallerySignature)),
        "mint: Invalid gallery signature.");

    require(hasRole(AUTHORIZER,
        ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toTypedDataHash(eip712DomainSeparator(), hash),
            approval.platformSignature)), "mint: Invalid platform signature.");
    require(msg.value == approval.price, "mint: Incorrect amount provided to mint.");
    require(approval.royaltyFee < 1 ether, "mint: Impossible royalty fee proposed.");

    require(approval.additionalFees.length == approval.additionalAddresses.length,
        "mint: Additional fees input is malformed.");
    uint totalAdditionalFees = 0;
    for (uint i = 0; i < approval.additionalFees.length; ++i) {
      totalAdditionalFees += approval.additionalFees[i];
      payable(approval.additionalAddresses[i]).transfer(approval.additionalFees[i]);
    }
    require(approval.platformFee + approval.galleryFee + totalAdditionalFees < approval.price,
        "mint: Impossible revenue split proposed.");

    _mint(_msgSender(), approval.tokenId);
    // Pay the gallery and artist immediately. Platform fees are held for later withdrawal.
    payable(approval.galleryAddress).transfer(approval.galleryFee);
    payable(approval.artistAddress).transfer(
        approval.price - approval.galleryFee - totalAdditionalFees - approval.platformFee);
    if (approval.royaltyFee > 0
          && AddressUpgradeable.isContract(approval.royaltyAddress)) {
      require(!RoyaltySplitter(payable(approval.royaltyAddress)).isClosed(),
          "mint: RoyaltySplitter contract has been closed");
    }
    royaltyData[approval.tokenId] = RoyaltyInfo(approval.royaltyAddress, approval.royaltyFee);
  }

  function royaltyInfo(uint tokenId, uint salePrice) external view override
      returns (address receiver, uint royaltyAmount) {
    require(_exists(tokenId), "royaltyInfo: Token does not exist");
    RoyaltyInfo memory info = royaltyData[tokenId];
    return (info.royaltyAddress, PRBMathUD60x18.mul(salePrice, info.royaltyFee));
  }

  function withdraw(uint amount) external onlyRole(WITHDRAWER) nonReentrant {
    require(amount > 0, "withdraw: Must specify a non-zero amount");
    require(amount <= address(this).balance, "withdraw: Insufficient balance to withdraw.");
    payable(_msgSender()).transfer(amount);
  }

  function tokenURI(uint tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "tokenURI: Token does not exist");
    return string(abi.encodePacked(baseTokenURI, StringsUpgradeable.toString(tokenId)));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual
      override(AccessControlUpgradeable, ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
    return interfaceId == type(IAccessControlUpgradeable).interfaceId
        || super.supportsInterface(interfaceId);
  }
}

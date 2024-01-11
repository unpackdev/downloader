// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//   ____           _   _ _             _      
//  / ___|_ __ __ _| |_(_) |_ _   _  __| | ___ 
// | |  _| '__/ _` | __| | __| | | |/ _` |/ _ \
// | |_| | | | (_| | |_| | |_| |_| | (_| |  __/
//  \____|_|  \__,_|\__|_|\__|\__,_|\__,_|\___|
//
// A collection of 2,222 unique Non-Fungible Power SUNFLOWERS living in 
// the metaverse. Becoming a GRATITUDE GANG NFT owner introduces you to 
// a FAMILY of heart-centered, purpose-driven, service-oriented human 
// beings.
//
// https://www.gratitudegang.io/
//

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Address.sol";
import "./Context.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IERC20Burnable is IERC20 {
  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   */
  function burnFrom(address account, uint256 amount) external;
}

// ============ Contract ============

contract GratitudeVault is Context, AccessControl, ReentrancyGuard {
  //used in buy()
  using Address for address;

  // ============ Structs ============
  
  struct NFT {
    address contractAddress; 
    uint256 tokenId;
    uint256 ethPrice; 
    uint256 tokenPrice; 
  }

  // ============ Constants ============

  bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

  IERC20Burnable public immutable GRATIS;

  // ============ Storage ============

  //the last id
  uint256 public lastId;
  //mapping of nftid to NFT
  mapping(uint256 => NFT) public nfts;

  // ============ Deploy ============

  constructor(IERC20Burnable gratis, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    GRATIS = gratis;
  }

  // ============ Read Methods ============

  /**
   * @dev allows to receive tokens
   */
  function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
  ) external pure returns(bytes4) {
    return 0x150b7a02;
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to buy an NFT from this vault with ETH
   */
  function buy(address recipient, uint256 nftId) external payable {
    //if there is a price and the amount sent is less than
    if (nfts[nftId].ethPrice == 0 || msg.value < nfts[nftId].ethPrice) 
      revert InvalidCall();
    //transfer out
    _transferOut(recipient, nftId);
  }

  /**
   * @dev Allows anyone to redeem with a voucher (proof)
   */
  function redeem(
    address recipient, 
    uint256 nftId,
    bytes memory voucher
  ) external nonReentrant {
    //make sure the minter signed this off
    if (!hasRole(MINTER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked("redeem", recipient, nftId))
      ),
      voucher
    ))) revert InvalidCall();
    //transfer out
    _transferOut(recipient, nftId);
  }

  /**
   * @dev Allows anyone to redeem an NFT from this vault with GRATIS
   */
  function support(address recipient, uint256 nftId) external nonReentrant {
    //burn it. muhahaha
    GRATIS.burnFrom(_msgSender(), nfts[nftId].tokenPrice);
    //transfer out
    _transferOut(recipient, nftId);
  }

  /**
   * @dev Allows anyone to deposit an NFT into the vault. This 
   * invokes a safe transfer
   */
  function safeTransferIn(
    address contractAddress, 
    uint256 tokenId, 
    uint256 ethPrice, 
    uint256 tokenPrice
  ) external {
    //transfer NFT to here
    IERC721(contractAddress).safeTransferFrom(
      _msgSender(), 
      address(this), 
      tokenId
    );
    //add nft pricing
    transferIn(
      contractAddress,
      tokenId,
      ethPrice,
      tokenPrice
    );
  }

  /**
   * @dev Allows anyone to deposit an NFT into the vault
   */
  function transferIn(
    address contractAddress, 
    uint256 tokenId, 
    uint256 ethPrice, 
    uint256 tokenPrice
  ) public {
    //add nft pricing
    nfts[++lastId] = NFT(
      contractAddress,
      tokenId,
      ethPrice,
      tokenPrice
    );
  }

  // ============ Admin Methods ============

  /**
   * @dev Allows a curator transfer NFT to recipient
   */
  function transferOut(
    address recipient,
    uint256 nftId
  ) external onlyRole(CURATOR_ROLE) {
    _transferOut(recipient, nftId);
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`. 
   */
  function withdraw(
    address recipient
  ) external nonReentrant onlyRole(FUNDER_ROLE) {
    Address.sendValue(payable(recipient), address(this).balance);
  }

  // ============ Internal Methods ============

  /**
   * @dev transfer NFT to recipient
   */
  function _transferOut(address recipient, uint256 nftId) internal {
    IERC721(nfts[nftId].contractAddress).safeTransferFrom(
      address(this), 
      recipient, 
      nfts[nftId].tokenId
    );
  }
}
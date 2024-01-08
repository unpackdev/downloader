// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./CountersUpgradeable.sol";

contract LaunchNFTStorageV0 {
  /**
   * @dev mint price
   */
  uint256 public price;

  /**
   * @dev whitelist price
   */
  uint256 public whitelistPrice;

  /*
   * @dev maxPurchaseNum
   */
  uint256 public maxPurchaseNum;

  /**
   * @dev maxSupply
   */
  uint256 public maxSupply;

  /**
   * @dev baseURI
   */
  string public baseURI;

  /**
   * @dev number of total reserved NFTs
   */
  uint256 public reserveNum;

  /**
   * @dev number of reserved NFTs minted
   */
  uint256 public mintedReserveNum;

  /**
   * @dev The current id of NFTs. Auto increment.
   */
  CountersUpgradeable.Counter public id;

  /**
   * @dev is minting active.
   */
  bool public isMintingActive = false;

  /**
   * @dev signer for whitelist sale
   */
  address public whitelistSigner;

  /**
   * @dev hasMinted stores all the whitelist sale result
   */
  mapping(uint256 => bool) public hasMinted;
}

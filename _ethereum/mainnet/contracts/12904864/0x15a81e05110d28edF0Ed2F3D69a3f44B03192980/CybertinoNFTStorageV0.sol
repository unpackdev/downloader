// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./CountersUpgradeable.sol";

// Storage is append only and never to be modified
// To upgrade:
//
// contract CybertinoNFTStorageV1 is CybertinoNFTStorageV0 {...}
// contract CybertinoNFTV1 is CybertinoNFTStorageV1 ... {...}
contract CybertinoNFTStorageV0 {
  /**
   * @dev collection name; token tracker name
   */
  string public name;

  /**
   * @dev The current id of NFTs. Auto increment.
   */
  CountersUpgradeable.Counter public id;

  /**
   * @dev Cybertino Platform signer
   */
  address public signer;

  /**
   * @dev Mapping from token ID to token URI, excluding base uri
   */
  mapping(uint256 => string) internal idToUri;

  /**
   * @dev Mapping from token ID to token max supply
   */
  mapping(uint256 => uint256) internal maxTokenSupply;

  /**
   * @dev Mapping from token ID to token supply, how many minted
   */
  mapping(uint256 => uint256) internal tokenSupply;

  /**
   * @dev Mapping from signature hash to boolean to prevent replay
   */
  mapping(bytes32 => bool) public executed;

  /**
   * @dev Paused boolean is turned on in case of emergency.
   */
  bool public paused = false;

  /**
   * @dev collection symbol; token tracker symbol
   */
  string public symbol;
}

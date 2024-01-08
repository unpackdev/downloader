// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ILayer.sol";
import "./CountersUpgradeable.sol";

// Storage is append only and never to be modified
// To upgrade:
//
// contract InfluencerStorageV1 is InfluencerStorageV0 {...}
// contract InfluencerV1 is InfluencerStorageV1 ... {...}
contract InfluencerStorageV0 {
  /**
   * @dev influencer name
   */
  string public name;
  /**
   * @dev collection symbol; token tracker symbol
   */
  string public symbol;

  /**
   * @dev The current id of NFTs. Auto increment.
   */
  CountersUpgradeable.Counter public id;

  /**
   * @dev LayerToken stores layer contract address and layer token id
   */
  struct LayerToken {
      // layer contract address
      ILayer layer;
      // layer token id
      uint256 layerID;
  }

  /**
   * Canvas consists of 1 or more layers
   */
  struct Canvas {
      // canvas id
      uint256 id;
      // The total number of layers
      uint256 layerCount;
      // all layer tokens
      mapping(uint256 => LayerToken) layerTokens;
  }


  /**
   * @dev tokenID to Canvas
   */
  mapping(uint256 => Canvas) public canvases;

  /**
   * @dev Cybertino Platform signer
   */
  address public signer;

  // TODO: multiple mapping or mapping of struct
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
}

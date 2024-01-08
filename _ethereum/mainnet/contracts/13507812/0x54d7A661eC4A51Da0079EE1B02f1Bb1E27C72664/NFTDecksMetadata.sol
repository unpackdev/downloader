// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./BlindDrop.sol";
import "./Base64.sol";
import "./ERC721EnumerableOptimized.sol";
import "./NFTDecksConstants.sol";

/**
 * @title NFTDecksMetadata
 *
 * @notice Logic for generating metadata, including the SVG graphic with text.
 *
 *  Based closely on the original Loot implementation (MIT License).
 *  https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1
 */
abstract contract NFTDecksMetadata is
  BlindDrop,
  ERC721EnumerableOptimized
{
  function random(
    string memory input
  )
    internal
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getWeapon(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.WEAPON);
  }

  function getChest(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.CHEST);
  }

  function getHead(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.HEAD);
  }

  function getWaist(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.WAIST);
  }

  function getFoot(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.FOOT);
  }

  function getHand(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.HAND);
  }

  function getWEAPON2(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.WEAPON2);
  }

  function getWEAPON3(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, NFTDecksConstants.ListName.WEAPON3);
  }

  function pluck(
    uint256 tokenId,
    NFTDecksConstants.ListName keyPrefix
  )
    internal
    view
    returns (string memory)
  {
    // Get the blind drop seed. Will revert if the distribution is not complete or if the seed
    // has not yet been finalized.
    bytes32 seed = getFinalSeed();

    // On-chain randomness.
    string memory inputForRandomness = string(abi.encodePacked(
      keyPrefix,
      tokenId, // Note: No need to use toString() here.
      seed
    ));
    uint256 rand = random(inputForRandomness);

    // Determine the item name based on the randomly generated number.
    string memory output = NFTDecksConstants.getItem(rand, keyPrefix);
    uint256 greatness = rand % 21;
    if (greatness > 14) {
      output = string(abi.encodePacked(output, " ", NFTDecksConstants.getItem(rand, NFTDecksConstants.ListName.SUFFIX)));
    }
    if (greatness >= 19) {
      string[2] memory name;
      name[0] = NFTDecksConstants.getItem(rand, NFTDecksConstants.ListName.NAME_PREFIX);
      name[1] = NFTDecksConstants.getItem(rand, NFTDecksConstants.ListName.NAME_SUFFIX);
      if (greatness == 19) {
        output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
      } else {
        output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
      }
    }
    return output;
  }

  function tokenURI(
    uint256 tokenId
  )
    override
    public
    view
    returns (string memory)
  {
    string[17] memory parts;
    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
    parts[1] = getWeapon(tokenId);
    parts[2] = '</text><text x="10" y="40" class="base">';
    parts[3] = getChest(tokenId);
    parts[4] = '</text><text x="10" y="60" class="base">';
    parts[5] = getHead(tokenId);
    parts[6] = '</text><text x="10" y="80" class="base">';
    parts[7] = getWaist(tokenId);
    parts[8] = '</text><text x="10" y="100" class="base">';
    parts[9] = getFoot(tokenId);
    parts[10] = '</text><text x="10" y="120" class="base">';
    parts[11] = getHand(tokenId);
    parts[12] = '</text><text x="10" y="140" class="base">';
    parts[13] = getWEAPON2(tokenId);
    parts[14] = '</text><text x="10" y="160" class="base">';
    parts[15] = getWEAPON3(tokenId);
    parts[16] = '</text></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "Bag #',
      NFTDecksConstants.toString(tokenId),
      '", "description": "NFTDecks are randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(output)),
      '"}'
    ))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }
}

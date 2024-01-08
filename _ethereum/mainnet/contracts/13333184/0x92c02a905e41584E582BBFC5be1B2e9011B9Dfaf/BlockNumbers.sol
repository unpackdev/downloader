// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";

import "./Base64.sol";
import "./ERC721EnumerableOptimized.sol";

/**
 * @title BlockNumbers
 * @author the-torn
 *
 * @notice Mint block numbers as NFTs.
 *
 *  There is deliberately no maximum supply, to discourage minting numbers that aren't cool.
 */
contract BlockNumbers is
  ERC721EnumerableOptimized
{
  uint256 internal _totalSupply = 0;
  mapping(uint256 => uint256) internal _blockNumbers;
  mapping(uint256 => bool) internal _isBlockNumberClaimed;

  constructor()
    ERC721("Block Numbers", "BLOCK#")
  {}

  /**
   * @notice Claim a token only if the block number matches the desired block number.
   */
  function claimIf(
    uint256 desiredBlockNumber
  )
    external
  {
    require(
      block.number == desiredBlockNumber,
      "Block number mismatch"
    );
    claim();
  }

  /**
   * @notice Claim a token.
   */
  function claim()
    public
  {
    uint256 blockNumber = block.number;
    require(
      !_isBlockNumberClaimed[blockNumber],
      "Block number was claimed"
    );

    // Issue tokens with IDs 1 through MAX_SUPPLY, inclusive.
    uint256 tokenId = _totalSupply + 1;

    // IMPORTANT: Update state before _safeMint() to avoid reentrancy attacks.
    // (checks-effects-interactions)
    _totalSupply = tokenId;
    _blockNumbers[tokenId] = blockNumber;
    _isBlockNumberClaimed[blockNumber] = true;

    // Mint the token. This may trigger a call on the receiver if it is a smart contract.
    _safeMint(msg.sender, tokenId);
  }

  function totalSupply()
    public
    view
    override
    returns (uint256)
  {
    return _totalSupply;
  }

  function getBlockNumber(
    uint256 tokenId
  )
    external
    view
    returns (uint256)
  {
    require(
      tokenId != 0 && tokenId <= _totalSupply,
      "Invalid token ID"
    );
    return _blockNumbers[tokenId];
  }

  function getIsBlockNumberClaimed(
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    return _isBlockNumberClaimed[blockNumber];
  }

  /**
   * @notice Get the token URI. Contains the SVG rendering logic.
   */
  function tokenURI(
    uint256 tokenId
  )
    override
    public
    view
    returns (string memory)
  {
    string[3] memory parts;
    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.t { fill: white; font-family: serif; font-size: 36px; }</style><rect width="100%" height="100%" fill="black" /><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" class="t">';
    parts[1] = toString(_blockNumbers[tokenId]);
    parts[2] = '</text></svg>';

    string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2]));

    string memory metadataJson = Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "Block #',
      parts[1],
      '", "description": "This token was minted at block #',
      parts[1],
      '.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '"}'
    ))));

    return string(abi.encodePacked('data:application/json;base64,', metadataJson));
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   *
   *  Based on OraclizeAPI's implementation (MIT licence).
   *  https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
   */
  function toString(
    uint256 value
  )
    internal
    pure
    returns (string memory)
  {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ConceptualProjectParts.sol";

/**
The Conceptual Project is a collection of randomly generated conceptual metaphors generated and
stored entirely on the Ethereum blockchain. These abstract thoughts and ideas can inspire endless
interpretations and use cases. Feel free to use these concepts in any way you see fit.

conceptualproject.io
*/

contract ConceptualProject is ERC721Enumerable, ReentrancyGuard, Ownable {
  uint256 private naturalCount;
  uint256 private syntheticCount;

  bool private allNaturalsClaimed = false;
  uint256 private syntheticUnlockTimestamp;

  constructor() ERC721("ConceptualProject", "CONCEPT") {}

  function getTargetDomain(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    uint256 rand = _random(
      string(abi.encodePacked("TARGET_DOMAIN", Strings.toString(_tokenId)))
    );

    string[6] memory possesiveAdjectives = ConceptualProjectParts
    .getPossessiveAdjectives();
    string[3] memory linkingVerbs = ConceptualProjectParts.getLinkingVerbs();
    string[188] memory targetDomains = ConceptualProjectParts
    .getTargetDomains();

    uint8[2][3] memory targetDomainIndexRangeToLinkingVerbIndex = [
      [122, 0],
      [157, 1],
      [188, 2]
    ];

    uint256 possessiveAdjectiveIndex = rand % possesiveAdjectives.length;
    uint256 targetDomainIndex = rand % targetDomains.length;
    uint256 linkingVerbIndex = _getPartConnectorIndex(
      targetDomainIndex,
      targetDomainIndexRangeToLinkingVerbIndex
    );

    if (targetDomainIndex > 157) {
      possessiveAdjectiveIndex = (rand % (possesiveAdjectives.length - 1)) + 1;
    }

    if (possessiveAdjectiveIndex == 0) {
      return
        string(
          abi.encodePacked(
            _capitalizeString(targetDomains[targetDomainIndex]),
            " ",
            linkingVerbs[linkingVerbIndex]
          )
        );
    } else {
      return
        string(
          abi.encodePacked(
            possesiveAdjectives[possessiveAdjectiveIndex],
            " ",
            targetDomains[targetDomainIndex],
            " ",
            linkingVerbs[linkingVerbIndex]
          )
        );
    }
  }

  function getSourceDomain(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    uint256 rand = _random(
      string(abi.encodePacked("SOURCE_DOMAIN", Strings.toString(_tokenId)))
    );

    string[4] memory articles = ConceptualProjectParts.getArticles();
    string[124] memory sourceDomains = ConceptualProjectParts
    .getSourceDomains();

    uint8[2][3] memory sourceDomainIndexRangeToArticlesIndex = [
      [19, 0],
      [25, 1],
      [124, 2]
    ];

    uint256 sourceDomainIndex = rand % sourceDomains.length;
    uint256 articleIndex = _getPartConnectorIndex(
      sourceDomainIndex,
      sourceDomainIndexRangeToArticlesIndex
    );

    return
      string(
        abi.encodePacked(
          articles[articleIndex],
          " ",
          sourceDomains[sourceDomainIndex]
        )
      );
  }

  function tokenURI(uint256 _tokenId)
    public
    pure
    override
    returns (string memory)
  {
    string[14] memory parts;

    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" width="500" height="500" viewBox="0 0 350 350">';

    parts[1] = "<style>.base { fill: ";

    parts[2] = _tokenId <= 10000 ? "white" : "black";

    parts[3] = "; font-family: serif; font-size: 14px; }</style>";

    parts[4] = '<rect width="100%" height="100%" fill="';

    parts[5] = _tokenId <= 10000 ? "black" : "white";

    parts[6] = '" />';

    parts[
      7
    ] = '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" class="base">';

    parts[8] = getTargetDomain(_tokenId);

    parts[9] = " ";

    parts[10] = getSourceDomain(_tokenId);

    parts[11] = ".";

    parts[12] = "</text>";

    parts[13] = "</svg>";

    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8]
      )
    );

    output = string(
      abi.encodePacked(
        output,
        parts[9],
        parts[10],
        parts[11],
        parts[12],
        parts[13]
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            "{",
            '"name": "Concept #',
            Strings.toString(_tokenId),
            '",',
            '"description": "The Conceptual Project is a collection of randomly generated conceptual metaphors generated and stored entirely on the Ethereum blockchain. These abstract thoughts and ideas can inspire endless interpretations and use cases. Feel free to use these concepts in any way you see fit.",',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '",',
            '"attributes":[{"trait_type": "Type", "value": ',
            _tokenId <= 10000 ? '"Natural"' : '"Synthetic"',
            "}]"
            "}"
          )
        )
      )
    );

    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  function claimNatural(uint256 _tokenId) public nonReentrant {
    require(_tokenId > 0 && _tokenId < 9501, "Natural token ID invalid");

    naturalCount += 1;

    if (naturalCount >= 9000 && !allNaturalsClaimed) {
      syntheticUnlockTimestamp = block.timestamp + 5 days;
      allNaturalsClaimed = true;
    }

    _safeMint(_msgSender(), _tokenId);
  }

  function claimSynthetic(uint256 _tokenId) public nonReentrant {
    require(_tokenId > 10000 && _tokenId < 39501, "Synthetic token ID invalid");

    require(allNaturalsClaimed, "All Naturals must be claimed to unlock");
    require(
      block.timestamp >= syntheticUnlockTimestamp,
      "Unlock delay not met"
    );

    if (block.timestamp <= syntheticUnlockTimestamp + 5 days) {
      require((syntheticCount + 1) <= 5000, "Current unlock limit reached");
    } else if (block.timestamp <= syntheticUnlockTimestamp + 10 days) {
      require((syntheticCount + 1) <= 10000, "Current unlock limit reached");
    } else if (block.timestamp <= syntheticUnlockTimestamp + 15 days) {
      require((syntheticCount + 1) <= 15000, "Current unlock limit reached");
    } else if (block.timestamp <= syntheticUnlockTimestamp + 20 days) {
      require((syntheticCount + 1) <= 20000, "Current unlock limit reached");
    } else if (block.timestamp <= syntheticUnlockTimestamp + 25 days) {
      require((syntheticCount + 1) <= 25000, "Current unlock limit reached");
    }

    syntheticCount += 1;

    _safeMint(_msgSender(), _tokenId);
  }

  function ownerClaimNatural(uint256[] calldata _tokenIds)
    public
    nonReentrant
    onlyOwner
  {
    address account = owner();

    for (uint256 i; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];

      require(tokenId > 9500 && tokenId < 10001);

      _safeMint(account, tokenId);
    }
  }

  function ownerClaimSynthetic(uint256[] calldata _tokenIds)
    public
    nonReentrant
    onlyOwner
  {
    require(allNaturalsClaimed);
    require(block.timestamp >= syntheticUnlockTimestamp);

    address account = owner();

    for (uint256 i; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];

      require(tokenId > 39500 && tokenId < 40001);

      _safeMint(account, tokenId);
    }
  }

  function _getPartConnectorIndex(uint256 _index, uint8[2][3] memory _rangeList)
    internal
    pure
    returns (uint256 _connectorIndex)
  {
    require(_rangeList.length <= 3);

    for (uint256 i = 0; i < _rangeList.length; i++) {
      if (_index <= _rangeList[i][0]) {
        return _rangeList[i][1];
      }
    }
  }

  function _random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function _capitalizeString(string memory _string)
    internal
    pure
    returns (string memory)
  {
    bytes memory lowercase = bytes("abcdefghijklmnopqrstuvwxyz");
    bytes memory uppercase = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    bytes memory buffer = bytes(_string);

    for (uint256 i = 0; i < lowercase.length; i++) {
      if (buffer[0] == lowercase[i]) {
        buffer[0] = uppercase[i];
        return string(buffer);
      }
    }

    return string(buffer);
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

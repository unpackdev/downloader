// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Base64.sol";
import "./StringList.sol";

library FormatMetadata {
  using Base64 for bytes;
  using StringList for string[];
  using Strings for uint256;

  function formatTraitString(string memory traitType, string memory value)
    internal
    pure
    returns (string memory)
  {
    if (bytes(value).length == 0) {
      return "";
    }
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":"',
          value,
          '"}'
        )
      );
  }

  function formatTraitNumber(
    string memory traitType,
    uint256 value,
    string memory displayType
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":',
          value.toString(),
          ',"display_type":"',
          displayType,
          '"}'
        )
      );
  }

  function formatTraitNumber(
    string memory traitType,
    int256 value,
    string memory displayType
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":',
          intToString(value),
          ',"display_type":"',
          displayType,
          '"}'
        )
      );
  }

  function formatMetadata(
    string memory name,
    string memory description,
    string memory image,
    string[] memory attributes,
    string memory additionalMetadata
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          bytes(
            abi.encodePacked(
              '{"name": "',
              name,
              '", "description": "',
              description,
              '", "image": "',
              image,
              '", "attributes": [',
              attributes.join(", ", true),
              "]",
              bytes(additionalMetadata).length > 0 ? "," : "",
              additionalMetadata,
              "}"
            )
          ).encode()
        )
      );
  }

  function formatMetadataWithSVG(
    string memory name,
    string memory description,
    string memory svg,
    string[] memory attributes,
    string memory additionalMetadata
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          bytes(
            abi.encodePacked(
              '{"name": "',
              name,
              '", "description": "',
              description,
              '", "image_data": "',
              svg,
              '", "attributes": [',
              attributes.join(", ", true),
              "]",
              bytes(additionalMetadata).length > 0 ? "," : "",
              additionalMetadata,
              "}"
            )
          ).encode()
        )
      );
  }

  function intToString(int256 n) internal pure returns (string memory) {
    uint256 nAbs = n < 0 ? uint256(-n) : uint256(n);
    bool nNeg = n < 0;
    return string(abi.encodePacked(nNeg ? "-" : "", nAbs.toString()));
  }
}

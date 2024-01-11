// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Strings.sol";
import "./StringsLib.sol";
import "./IToken.sol";
import "./IAttribute.sol";

/// @notice library functions to create an opensea-standard metadata object:
library MetadataCreator {

  struct Trait {
    string displayType;
    string key;
    string value;
  }

  struct Metadata {
    string name;
    string symbol;
    string description;
    string imageUrl;
    string externalUrl;
  }

  /// @notice create a metadata trait
  function createTrait(
    string memory displayType,
    string memory key,
    string memory value
  ) internal pure returns (string memory trait) {
    require(bytes(key).length > 0, "key cannot be empty");
    bool hasDisplayType = bytes(displayType).length > 0;
    if(hasDisplayType) {
      displayType = string(abi.encodePacked('"display_type": "',displayType, '",'));
    } else {
      displayType = "";
      value = string(abi.encodePacked('"', value, '"'));
    }
    trait = string(
        abi.encodePacked(
            "{", 
            displayType,
            '"trait_type": "',
            key,
            '", "value": ',
            value,
            "}"
        )
    );
  }

  /// @notice given an array of trait structs, create a metadata string
  function arrayizeTraits(Trait[] memory _traits)
    internal
    pure
    returns (string memory _traitsString)
  {
    bytes memory traitBytes = "[";
    for (uint256 i = 0; i < _traits.length; i++) {
      Trait memory traitObj = _traits[i];
      string memory trait = createTrait(
        traitObj.displayType,
        traitObj.key,
        traitObj.value
      );
      traitBytes = abi.encodePacked(traitBytes, trait);
      if (i < _traits.length - 1) {
        traitBytes = abi.encodePacked(traitBytes, ",");
      }
    }
    _traitsString = string(abi.encodePacked(traitBytes, "]"));
  }

  /// @notice create a metadata string from a metadata struct
  function createMetadataJSON(
    Metadata memory _metadata,
    MetadataCreator.Trait[] memory _traits
    )
    internal
    pure
    returns (string memory metadata)
  {
    string memory traitsString = arrayizeTraits(_traits);

      bytes memory a1 = abi.encodePacked(
        '{"name": "',
        _metadata.name,
        '", "image_url": "',
        _metadata.imageUrl,
        '", "external_url": "',
        _metadata.externalUrl,
        '", "description": "',
        _metadata.description,
        '"'
      );
      if(_traits.length > 0) {
        a1 = abi.encodePacked(a1, ', "attributes": ', traitsString);
      }
      metadata = string ( abi.encodePacked(a1, "}") );

  }
}

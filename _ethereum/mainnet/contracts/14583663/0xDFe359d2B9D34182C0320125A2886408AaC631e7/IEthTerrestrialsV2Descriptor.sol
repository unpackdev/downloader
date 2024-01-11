interface IEthTerrestrialsV2Descriptor {
   struct TraitType {
      string name;
      uint16[] rarity;
   }
   struct Trait {
      address imageStore;
      uint96 imagelen;
      string name;
   }
   struct TraitDescriptor {
      uint8 traitType;
      uint8 trait;
   }

   function contractsealed() external view returns (bool);

   function customs(uint256)
      external
      view
      returns (
         address imageStore,
         uint96 imagelen,
         string memory name
      );

   function decompress(bytes memory input, uint256 len) external pure returns (string memory);

   function enforceRequiredCombinations(uint8[10] memory seed) external view returns (uint8[10] memory);

   function generateTokenURI(
      uint256 tokenId,
      uint256 rawSeed,
      uint256 tokenType
   ) external view returns (string memory);

   function getArrangedSeed(uint8[10] memory seed) external view returns (uint8[20] memory);

   function getSvgCustomToken(uint256 tokenId) external view returns (string memory);

   function getSvgFromSeed(uint8[10] memory seed) external view returns (string memory);

   function getTraitSVG(uint8 traitType, uint8 traitCode) external view returns (string memory);

   function processRawSeed(uint256 rawSeed) external view returns (uint8[10] memory);

   function sealContract() external;

   function setCustom(uint256[] memory _tokenIds, Trait[] memory _oneOfOnes) external;

   function setHiddenTraits(uint8[] memory _traitTypes, bool _hidden) external;

   function setTraitExclusions(
      uint8 traitType,
      uint8 trait,
      TraitDescriptor[] memory exclusions
   ) external;

   function setTraitRearrangements(
      uint8 traitType,
      uint8 trait,
      TraitDescriptor[] memory rearrangements
   ) external;

   function setTraitTypes(TraitType[] memory _traitTypes) external;

   function setTraits(
      uint8 _traitType,
      Trait[] memory _traits,
      uint8[] memory _traitNumber
   ) external;

   function terraforms() external view returns (address);

   function traitExclusions(bytes32, uint256) external view returns (uint8 traitType, uint8 trait);

   function traitRearrangement(bytes32, uint256) external view returns (uint8 traitType, uint8 trait);

   function traitTypes(uint8) external view returns (string memory name);

   function traits(uint8, uint8)
      external
      view
      returns (
         address imageStore,
         uint96 imagelen,
         string memory name
      );

   function viewTraitsJSON(uint8[10] memory seed) external view returns (string memory);

   function viewTraitsJSONCustom(uint256 tokenId) external view returns (string memory);
}

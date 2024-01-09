// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./VRFConsumerBase.sol";
import "./Base64.sol";
import "./FormatMetadata.sol";
import "./StringList.sol";
import "./ITrait.sol";
import "./Bodies.sol";
import "./Eyes.sol";
import "./Hats.sol";
import "./Mouths.sol";
import "./Pants.sol";
import "./Tops.sol";
import "./ICritterzMetadata.sol";

contract CritterzMetadata is ICritterzMetadata, Ownable, VRFConsumerBase {
  using Base64 for bytes;
  using Strings for uint256;
  using StringList for string[];

  string internal constant HEADER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
  string internal constant FRONT_HEADER_PLACEHOLDER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
  string internal constant FRONT_HEADER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="background-color:';
  string internal constant FRONT_HEADER_CLOSING = '">';
  string internal constant FOOTER =
    "<style>#critterz{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

  string internal constant PNG_HEADER =
    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_HEADER_PLACEHOLDER =
    '<image x="0" y="0" width="40" height="40" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FRONT_HEADER =
    '<image x="12" y="4" width="16" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FRONT_ARMOR_HEADER =
    '<image x="11" y="3" width="18" height="36" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FOOTER = '"/>';

  string internal constant STAKED_LAYER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAAeDwA4HABcLRlnPizWq/oQAAAAAXRSTlMAQObYZgAAAC9JREFUGNNjYBgsQAlKM5koQBgqzhAGk7GTAJgh7GIEYYiYKELVOkMZDEICtHEVAG0PAxFGcat9AAAAAElFTkSuQmCC";

  string internal constant PLACEHOLDER_LAYER =
    "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAElBMVEVQOAPvmQDxwgD/0Aro6N/////AfLfFAAAAiUlEQVQoz63S0QnDMAwE0ANN4GaDm8Do6ACFDFAo2n+VOh8lQdaHodHnwzpjydiLwk2oURPCCuyCFe1da5kbzDO+WhNnfDCj1LYzFec1FUbM+Iz4ZPQAQp7RFJaxVzhS3wUGciaPg7+HXlEJSQkiV+Z5tC/iyFzbUY0u/wc5r3h3+owkeff3vtYXMN7FTEvCxhsAAAAASUVORK5CYII=";

  address public bodies;
  address public eyes;
  address public mouths;
  address public pants;
  address public tops;
  address public hats;
  address public backgrounds;

  uint256 public override seed;

  bytes32 internal keyHash;
  uint256 internal fee;

  string internal _description;

  string internal _stakedDescription;

  struct TraitLayer {
    string name;
    string skinLayer;
    string frontLayer;
    string frontArmorLayer;
    uint256 bodyIndex;
  }

  constructor(
    address _bodies,
    address _eyes,
    address _mouths,
    address _pants,
    address _tops,
    address _hats,
    address _backgrounds,
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(_vrfCoordinator, _link) {
    bodies = _bodies;
    eyes = _eyes;
    mouths = _mouths;
    pants = _pants;
    tops = _tops;
    hats = _hats;
    backgrounds = _backgrounds;
    keyHash = _keyHash;
    fee = _fee;

    _description = "The first fully on-chain NFT collection to enable P2E while playing Minecraft. Stake to generate $BLOCK tokens in-game and use $BLOCK tokens to claim Plots of in-game land as NFTs.";
    _stakedDescription = "You should ONLY get staked Critterz from here if you want to RENT a Critter. These are NOT the same as Critterz NFTs -- staked Critterz have a steak in their hands. Rented Critterz also give access to the Critterz Minecraft world but generates less $BLOCK and are time limited.";
  }

  /*
  READ FUNCTIONS
  */

  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view override returns (string memory) {
    TraitLayer[8] memory traitLayers;

    traitLayers[0] = _getTrait(bodies, tokenId, 0);
    traitLayers[1] = _getTrait(eyes, tokenId, traitLayers[0].bodyIndex % 6);
    traitLayers[2] = _getTrait(mouths, tokenId, traitLayers[0].bodyIndex % 6);
    traitLayers[3] = _getTrait(pants, tokenId, 0);
    traitLayers[4] = _getTrait(tops, tokenId, 0);
    traitLayers[5] = _getTrait(hats, tokenId, 0);
    traitLayers[6] = _getTrait(backgrounds, tokenId, 0);

    string memory skinSvg = _getSkinSvg(
      traitLayers[0].skinLayer,
      traitLayers[1].skinLayer,
      traitLayers[2].skinLayer,
      traitLayers[3].skinLayer,
      traitLayers[4].skinLayer,
      traitLayers[5].skinLayer
    );

    string memory frontSvg = _getFrontSvg(
      traitLayers[0].frontLayer,
      traitLayers[1].frontLayer,
      traitLayers[2].frontLayer,
      traitLayers[3].frontLayer,
      traitLayers[4].frontLayer,
      traitLayers[5].frontLayer,
      traitLayers[5].frontArmorLayer,
      traitLayers[6].frontLayer,
      staked
    );

    string[] memory attributes = _getAttributes(
      traitLayers[0].name,
      traitLayers[1].name,
      traitLayers[2].name,
      traitLayers[3].name,
      traitLayers[4].name,
      traitLayers[5].name,
      traitLayers[6].name,
      additionalAttributes
    );

    return _formatMetadata(tokenId, skinSvg, frontSvg, attributes, staked);
  }

  function getPlaceholderMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view override returns (string memory) {
    string memory svg = _getPlaceholderSvg(staked);
    return _formatMetadata(tokenId, svg, svg, additionalAttributes, staked);
  }

  function _getFrontSvg(
    string memory bodyLayer,
    string memory eyeLayer,
    string memory mouthLayer,
    string memory pantsLayer,
    string memory topLayer,
    string memory hatLayer,
    string memory hatFrontLayer,
    string memory backgroundHex,
    bool staked
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _formatBackgroundHeader(backgroundHex),
          _formatLayer(bodyLayer, true, false),
          _formatLayer(eyeLayer, true, false),
          _formatLayer(mouthLayer, true, false),
          _formatLayer(pantsLayer, true, false),
          _formatLayer(topLayer, true, false),
          _formatLayer(hatLayer, true, false),
          _formatLayer(hatFrontLayer, true, true),
          staked ? _formatLayer(STAKED_LAYER, true, false) : "",
          FOOTER
        )
      );
  }

  function _getSkinSvg(
    string memory bodyLayer,
    string memory eyeLayer,
    string memory mouthLayer,
    string memory pantsLayer,
    string memory topLayer,
    string memory hatLayer
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          HEADER,
          _formatLayer(bodyLayer, false, false),
          _formatLayer(eyeLayer, false, false),
          _formatLayer(mouthLayer, false, false),
          _formatLayer(pantsLayer, false, false),
          _formatLayer(topLayer, false, false),
          _formatLayer(hatLayer, false, false),
          FOOTER
        )
      );
  }

  function _getPlaceholderSvg(bool staked)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          FRONT_HEADER_PLACEHOLDER,
          string(abi.encodePacked(PNG_HEADER_PLACEHOLDER, PLACEHOLDER_LAYER, PNG_FOOTER)),
          staked ? _formatLayer(STAKED_LAYER, true, false) : "",
          FOOTER
        )
      );
  }

  function _getAttributes(
    string memory bodyName,
    string memory eyeName,
    string memory mouthName,
    string memory pantsName,
    string memory topName,
    string memory hatName,
    string memory backgroundName,
    string[] memory additionalAttributes
  ) internal pure returns (string[] memory) {
    string[] memory attributes = new string[](7);
    attributes[0] = FormatMetadata.formatTraitString("Body", bodyName);
    attributes[1] = FormatMetadata.formatTraitString("Eye", eyeName);
    attributes[2] = FormatMetadata.formatTraitString("Mouth", mouthName);
    attributes[3] = FormatMetadata.formatTraitString("Pants", pantsName);
    attributes[4] = FormatMetadata.formatTraitString("Top", topName);
    attributes[5] = FormatMetadata.formatTraitString("Hat", hatName);
    attributes[6] = FormatMetadata.formatTraitString(
      "Background",
      backgroundName
    );

    return attributes.concat(additionalAttributes);
  }

  function _getTrait(
    address trait,
    uint256 tokenId,
    uint256 layerIndex
  ) public view returns (TraitLayer memory) {
    {
      ITrait traitContract = ITrait(trait);
      uint256 index;
      uint256 nonce;
      string memory name;
      string memory skinLayer;
      // resample if layer doesn't exist on sampled trait
      while (bytes(skinLayer).length == 0 && nonce < 15) {
        index = traitContract.sampleTraitIndex(
          _random(trait, tokenId, nonce++)
        );
        name = traitContract.getName(index);
        // skin layer doesn't have background trait and all background layers
        // are valid. If name is empty, it means trait is "None"
        if (trait == backgrounds || bytes(name).length == 0) {
          break;
        }
        skinLayer = traitContract.getSkinLayer(index, layerIndex);
      }
      string memory frontLayer = traitContract.getFrontLayer(index, layerIndex);
      string memory frontArmorLayer = traitContract.getFrontArmorLayer(
        index,
        layerIndex
      );
      TraitLayer memory traitStruct = TraitLayer(
        name,
        skinLayer,
        frontLayer,
        frontArmorLayer,
        index
      );
      return traitStruct;
    }
  }

  function _formatMetadata(
    uint256 tokenId,
    string memory svg,
    string memory frontSvg,
    string[] memory attributes,
    bool staked
  ) internal view returns (string memory) {
    return
      FormatMetadata.formatMetadata(
        string(
          abi.encodePacked(staked ? "s" : "", "Critterz #", tokenId.toString())
        ),
        staked ? _stakedDescription : _description,
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            bytes(frontSvg).encode()
          )
        ),
        attributes,
        string(
          abi.encodePacked(
            '"skinImage": "data:image/svg+xml;base64,',
            bytes(svg).encode(),
            '"'
          )
        )
      );
  }

  function _formatLayer(
    string memory layer,
    bool frontView,
    bool armorLayer
  ) internal pure returns (string memory) {
    if (!frontView) {
      assert(!armorLayer);
    }
    if (bytes(layer).length == 0) {
      return "";
    }
    if (frontView) {
      if (armorLayer) {
        return
          string(abi.encodePacked(PNG_FRONT_ARMOR_HEADER, layer, PNG_FOOTER));
      } else {
        return string(abi.encodePacked(PNG_FRONT_HEADER, layer, PNG_FOOTER));
      }
    } else {
      return string(abi.encodePacked(PNG_HEADER, layer, PNG_FOOTER));
    }
  }

  // Background exists only for the front view
  function _formatBackgroundHeader(string memory backgroundHex)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(FRONT_HEADER, backgroundHex, FRONT_HEADER_CLOSING)
      );
  }

  function _random(
    address trait,
    uint256 tokenId,
    uint256 nonce
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            seed,
            trait,
            tokenId,
            keccak256(abi.encodePacked(nonce))
          )
        )
      );
  }

  /*
  OWNER FUNCTIONS
  */

  function setAddresses(
    address _bodies,
    address _eyes,
    address _mouths,
    address _tops,
    address _pants,
    address _hats
  ) external onlyOwner {
    bodies = _bodies;
    eyes = _eyes;
    mouths = _mouths;
    tops = _tops;
    pants = _pants;
    hats = _hats;
  }

  function setDescription(string calldata description) external onlyOwner {
    _description = description;
  }

  function setStakedDescription(string calldata stakedDescription)
    external
    onlyOwner
  {
    _stakedDescription = stakedDescription;
  }

  function initializeSeed() external onlyOwner returns (bytes32 requestId) {
    require(seed == 0, "Seed already initialized");
    return requestRandomness(keyHash, fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    seed = randomness;
  }
}

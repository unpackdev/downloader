// contracts/Stradaverse.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Base64.sol";
import "./ProxyRegistry.sol";
import "./TraitsNames.sol";
import "./Utils.sol";

struct Traits {
  uint8 headgearId;
  uint8 faceMaskId;
  uint8 eyeId;
  uint8 corneaId;
  uint8 pupilId;
  uint8 footwearId;
  uint8 clothingId;
  uint8 backgroundId;
  uint8 skinColorId;
}

/// @title Stradaverse
/// @author Will Holley
contract Stradaverse is
  ERC721Upgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using StringsUpgradeable for uint256;
  using StringsUpgradeable for uint8;

  //////////////////////////////
  /// State
  //////////////////////////////

  /// @dev Mapping of ID to traits
  mapping(uint256 => Traits) private _traitMaps;

  /// @dev Ensuring trait combinations are unique.
  mapping(bytes32 => uint8) private _traitCombinationUniquenessHashes;

  /// @notice Funds paid to mint.
  uint256 public mintPayments;

  string public viewerBaseUrl;

  address public proxyRegistryAddress;

  string public thumbnailBaseUrl;

  //////////////////////////////
  /// Constructor
  //////////////////////////////

  /// @param proxyRegistryAddress_ OpenSea Proxy Registry Address
  /// @param viewerBaseUrl_ Base url of the viewer
  function initialize(
    address proxyRegistryAddress_,
    string memory viewerBaseUrl_
  ) public initializer {
    __ERC721_init("StradaVerse", "STRADAVERSE");
    __Ownable_init();

    mintPayments = 0;

    viewerBaseUrl = viewerBaseUrl_;
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  //////////////////////////////
  /// Minting
  //////////////////////////////

  /// @notice Creates a deterministicly unique hash a given set of traits.
  function computeTraitHash(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          headgearId_,
          faceMaskId_,
          eyeId_,
          corneaId_,
          pupilId_,
          footwearId_,
          clothingId_,
          backgroundId_,
          skinColorId_
        )
      );
  }

  /// @notice Verifies that a trait combination does not exist
  function validateTraitCombination(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public view returns (bytes32) {
    bytes32 traitHash = computeTraitHash(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    require(
      _traitCombinationUniquenessHashes[traitHash] == 0,
      "This trait combination has already been minted"
    );

    return traitHash;
  }

  /// @notice Mints one and sends it to message sender.
  /// @param headgearId_ Id
  /// @param faceMaskId_ Id
  /// @param eyeId_ Id
  /// @param corneaId_ Id
  /// @param pupilId_ Id
  /// @param footwearId_ Id
  /// @param clothingId_ Id
  /// @param backgroundId_ Id
  /// @param skinColorId_ Id
  function _mint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) internal {
    // Check that this trait has not already been minted.
    bytes32 traitHash = validateTraitCombination(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    // Save uniqueness hash
    _traitCombinationUniquenessHashes[traitHash] = 1;

    uint256 id = _owners.length;

    // Save traits struct
    _traitMaps[id] = Traits({
      headgearId: headgearId_,
      faceMaskId: faceMaskId_,
      eyeId: eyeId_,
      corneaId: corneaId_,
      pupilId: pupilId_,
      footwearId: footwearId_,
      clothingId: clothingId_,
      backgroundId: backgroundId_,
      skinColorId: skinColorId_
    });

    _safeMint(msg.sender, id);
  }

  /// @notice Mints one and sends it to message sender. Requires paying 0.777 Eth.
  /// @param headgearId_ Id
  /// @param faceMaskId_ Id
  /// @param eyeId_ Id
  /// @param corneaId_ Id
  /// @param pupilId_ Id
  /// @param footwearId_ Id
  /// @param clothingId_ Id
  /// @param backgroundId_ Id
  /// @param skinColorId_ Id
  function mint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public payable nonReentrant {
    require(msg.value == 0.0777 ether, "Mint cost is 0.0777 ETH");

    _mint(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    // Collect payment
    mintPayments += msg.value;
  }

  /// @notice Owner-only mint function.  Only requires paying gas.
  function ownerMint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public onlyOwner {
    _mint(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );
  }

  /// @notice Transfers funds to the contract owner.
  function collectMintPayments() public onlyOwner {
    require(mintPayments > 0, "No outstanding payments");
    address payable owner = payable(owner());
    owner.transfer(mintPayments);
    mintPayments = 0;
  }

  //////////////////////////////
  /// OpenSea
  //////////////////////////////

  /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
  /// See: https://github.com/ProjectOpenSea/opensea-creatures/blob/a0db5ede13ffb2d43b3ebfc2c50f99968f0d1bbb/contracts/TradeableERC721Token.sol#L66
  function isApprovedForAll(address owner_, address operator_)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner_)) == operator_) {
      return true;
    }

    return super.isApprovedForAll(owner_, operator_);
  }

  //////////////////////////////
  /// Metadata
  //////////////////////////////

  /// @dev Creates a metadata attribute object
  function _makeAttribute(string memory traitType_, string memory value_)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType_,
          '", "value":"',
          value_,
          '"}'
        )
      );
  }

  function tokenURI(uint256 id_) public view override returns (string memory) {
    require(_exists(id_), "ERC721Metadata: URI query for nonexistent token");

    string memory id = id_.toString();
    string memory name = string(abi.encodePacked("Strada #", id));
    string
      memory description = "StradaVerse is a community-driven metaverse project featuring worlds created by top independent artists. Strada's are customized before they are minted with no duplicates with a 10,000 collection size. Each Strada allows its owner to vote on experiences, activations, and artist grants paid for by the StradaVerse Charity. ";
    string memory pageUrl = string(abi.encodePacked(viewerBaseUrl, "/", id));

    Traits memory traits = _traitMaps[id_];

    // Note: need to use multiple strings because abi.encodePacked
    // has a maximum stack depth that would be exceeded otherwise.

    string memory traitsA = string(
      abi.encodePacked(
        "[",
        _makeAttribute("Headgear", TraitsNames.headgear(traits.headgearId)),
        ",",
        _makeAttribute("Face Mask", TraitsNames.faceMask(traits.faceMaskId)),
        ",",
        _makeAttribute("Eyes", TraitsNames.eye(traits.eyeId)),
        ",",
        _makeAttribute("Corneas", TraitsNames.cornea(traits.corneaId)),
        ",",
        _makeAttribute("Pupils", TraitsNames.pupil(traits.pupilId)),
        ",",
        _makeAttribute("Footwear", TraitsNames.footwear(traits.footwearId)),
        ",",
        _makeAttribute("Clothing", TraitsNames.clothing(traits.clothingId)),
        ","
      )
    );

    string memory traitsString = string(
      abi.encodePacked(
        traitsA,
        _makeAttribute(
          "Background",
          TraitsNames.background(traits.backgroundId)
        ),
        ",",
        _makeAttribute("Skin Color", TraitsNames.skinColor(traits.skinColorId)),
        "]"
      )
    );

    bytes32 traitHash = computeTraitHash(
      traits.headgearId,
      traits.faceMaskId,
      traits.eyeId,
      traits.corneaId,
      traits.pupilId,
      traits.footwearId,
      traits.clothingId,
      traits.backgroundId,
      traits.skinColorId
    );
    string memory traitHashStr = Utils.toHex(traitHash);

    string memory imageUrl = string(
      abi.encodePacked(
        thumbnailBaseUrl,
        Utils.lower(traitHashStr),
        ".jpg?alt=media"
      )
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '", "description":"',
                description,
                '", "animation_url": "',
                pageUrl,
                '", "image": "',
                imageUrl,
                '", "external_url": "',
                pageUrl,
                '", "attributes": ',
                traitsString,
                "}"
              )
            )
          )
        )
      );
  }

  //////////////////////////////
  /// Upgrades
  //////////////////////////////

  /// @dev 01-20211229
  function setThumbnailBaseUrl(string memory url_) public onlyOwner {
    thumbnailBaseUrl = url_;
  }
}

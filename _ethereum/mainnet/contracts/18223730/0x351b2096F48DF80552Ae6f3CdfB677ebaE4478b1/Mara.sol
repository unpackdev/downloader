// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IRegistry.sol";
import "./IVessel.sol";

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|           M a r a        |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error NonExistentToken();
error NotAuthorizedToClaim();
error UnauthorizedOwnerOfVessel();
error MismatchedSignature();

/**
 * @title Mara ERC-721 Smart Contract
 */
contract Mara is
  ERC721Upgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;

  uint256 public totalSupply;
  string private baseURI;

  IRegistry public registry;
  IVessel public vessel;

  address private signer;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _registryContract,
    address _vesselContract
  )
  external
  initializer
  {
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
    __AccessControlEnumerable_init();
    __ERC721_init("Mara", "MARA");

    registry = IRegistry(_registryContract);
    vessel = IVessel(_vesselContract);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function version()
  external
  pure
  virtual
  returns (string memory)
  {
    return "1.0.4";
  }

  function claimMaras(
    uint256[] calldata vesselIds,
    bytes memory signature
  )
  external
  nonReentrant
  {
    if (!_verify(msg.sender, vesselIds, signature)) {
      revert MismatchedSignature();
    }

    uint256 vesselIdsLength = vesselIds.length;

    for (uint256 i; i < vesselIdsLength;) {
      _claimMara(vesselIds[i]);

      unchecked {
        ++i;
      }
    }

    unchecked {
      totalSupply += vesselIdsLength;
    }
  }

  function _claimMara(
    uint256 vesselId
  )
  internal
  {
    if (vessel.ownerOf(vesselId) != msg.sender) {
      revert NotAuthorizedToClaim();
    }

    _mint(msg.sender, vesselId);
    vessel.burn(vesselId);
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override
  returns (string memory)
  {
    if (!_exists(tokenId)) {
      revert NonExistentToken();
    }

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI()
  internal
  view
  override
  returns (string memory)
  {
    return baseURI;
  }

  function setBaseURI(string memory uri)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseURI = uri;
  }

  function setSigner(address _signer)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    signer = _signer;
  }

  function _verify(
    address wallet,
    uint256[] calldata vesselIds,
    bytes memory signature
  )
  internal
  view
  returns (bool)
  {
    return signer == keccak256(abi.encodePacked(
      wallet,
      vesselIds
    )).toEthSignedMessageHash().recover(signature);
  }

  /**
    * @notice Checks whether operator is valid on the registry. Will return true if registry isn't active.
    * @param operator - Operator address
    */
  function _isValidAgainstRegistry(address operator)
  internal
  view
  returns (bool)
  {
    return registry.isAllowedOperator(operator);
  }

  /**
    * @notice Checks whether msg.sender is valid on the registry. If not, it will
    * block the transfer of the token.
    * @param from - Address token is transferring from
    * @param to - Address token is transferring to
    * @param tokenId - Token ID being transfered
    * @param batchSize - Batch size
    */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  )
  internal
  virtual
  override
  {
    if (_isValidAgainstRegistry(msg.sender)) {
      super._beforeTokenTransfer(
        from,
        to,
        tokenId,
        batchSize
      );
    } else {
      revert IRegistry.NotAllowed();
    }
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC721Upgradeable, AccessControlEnumerableUpgradeable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}


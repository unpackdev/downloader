// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./RolesUpgradeable.sol";

//
//
//
//                                                                                                  .@@@%#@&&,(#.
//                                                                                                @@@@@@@@@@@@@@@@&%
//                                                                                               @@@@@@@@@@@@@@@/,@@(
//               &@@@%                                                                        /@@@&@@@@@@@@@@#//
//             @@@@@@@@                        /%@@@&@@@,                                   @@@@@@@@@@@@@@@@@@@@@#
//     &@@&@@@&@@@&@@@@..                  &@@@@@@&@@@@@@@&@@@@(                          @@@@@@&         (&@@@&
//     @@@@@@@@@@@@@@@@@@@@@@@@          ,@@@@@@@@@@@@@@@@@@@@@@@@,                     (@@@@&*   @@@&@/         &@@@@.
//      ,@@@@@@@@@@@@@@@@@@@@&          &@@@@@@@@@@@@@@@@@@@@@@@@@&@@@(                *@@@@@    ,&@@@@@@@@@@@@@@@@@@@&
//      &@@@@@@@@@@@@@@@@@%          &@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@              @@@@&      @@@@@@@@@@@@@@@@@@@&.
//   #@@@@@@@@@@@@&@@@@@@%         ,&@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@*    @@@@&     %&@@@@@@@@@@@@@@@&@@@@#
//  @@@@@@@@@@@@@@@@@@@@@@@       ,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@    &@@@@    &@@@@@@@@@@@@@@@@@@@@@@@(
// .&@@@@@@@@@@@@@@@@@@@@@@*      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@&     .@@@@*   *@&@@@@@@@@@@@@@@@@@@@@@
//  &@@@@@@@@@@@@@@@@@@@@@@       &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@&        @@@@(   *&@@@@@@@@@@@@@@@@@@@&
//    &@@@&@@@&@@@&@@@&@&         .&@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@&.        /&@@&#   (@@&@@@&@@@&@@@&@%
//     *@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@          .@@@@@@@@@@@@@@@@@@@@@@@&/
//   &@@@@@@@@@@@@@@@@@@@#          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@&              %@&@@@@@@@@@@@@@@@@@@@@
//    /@@@@@@@@@@@@@@@@@@/          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@/  #@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@
//   #@@@@@@@@@@@@&@@@@@@@&     (@&@@@@@@@@@,  .*%@@@&&&&&@@@@@@@@&@    *@@@@@@@@@&@         *@%* @@%&@@@@(.  %@@@&%@@
//      ,@@@(@@@@@/#@@@          ./@&&&&&&@%            &@@@@@@@@@&@@                               %@@@@&.   ,@@@@@@
//                                                        ,*.#&&%.,.
//
//

/// @title CoolERC721A
/// @author Adam Goodman
/// @notice Inventory contract
contract CoolERC721A is
  DefaultOperatorFiltererUpgradeable,
  ERC721AQueryableUpgradeable,
  ERC721ABurnableUpgradeable,
  PausableUpgradeable,
  RolesUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  uint256 public MAX_LIMIT;
  string public _baseTokenUri;
  string public _contractUri;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @dev Initialize the contract, called once.
  /// @dev Contract has both an owner and access control. Owner is required for setting operator registry functions.
  function initialize(
    string memory name,
    string memory symbol,
    string memory baseUri,
    uint256 maxLimit,
    string memory contractUri
  ) public virtual initializer initializerERC721A {
    __ERC721A_init(name, symbol);
    __DefaultOperatorFilterer_init();
    __Pausable_init();
    __Roles_init();
    __Ownable_init();
    __ERC721AQueryable_init();
    __ERC721ABurnable_init();
    __UUPSUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, msg.sender);

    MAX_LIMIT = maxLimit;
    _baseTokenUri = baseUri;
    _contractUri = contractUri;
  }

  /// @notice Returns the version of the implementation contract.
  /// @dev This function is used by the proxy to determine the version of the implementation contract.
  /// @return The version of the implementation contract.
  function version() public pure virtual returns (string memory) {
    return '1.0.0';
  }

  /// @notice Returns the contract URI for storefront level metadata
  /// @dev Ref. https://docs.opensea.io/docs/contract-level-metadata
  /// @return The contract URI
  function contractURI() external view virtual returns (string memory) {
    return _contractUri;
  }

  /// @notice Mint an amount of tokens to the given address
  /// @dev Can only be called by an account with the MINTER_ROLE
  ///      Will revert if called when paused, see _beforeTokenTransfer
  /// @param to The address to mint the token to
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 amount) external virtual onlyMinter {
    unchecked {
      if (_totalMinted() + amount > MAX_LIMIT) {
        revert MaxLimitReached(MAX_LIMIT);
      }
    }
    _safeMint(to, amount);
  }

  /// @notice Set the max limit of tokens that can be minted
  /// @dev Can only be called by a manager
  /// @param maxLimit The new max limit
  function setMaxLimit(uint256 maxLimit) public onlyManager {
    MAX_LIMIT = maxLimit;

    emit MaxLimitChanged(maxLimit);
  }

  /// @notice Externally exposes the _nextTokenId function
  /// @dev used for referencing when burning fractures
  /// @return The next token id
  function nextTokenId() external view virtual returns (uint256) {
    return _nextTokenId();
  }

  /// @notice Pauses all token transfers
  /// @dev Can only be called by a manager
  ///      Emit handled by {OpenZeppelin Pausable}
  function pause() external virtual onlyManager {
    _pause();
  }

  /// @notice Unpauses all token transfers
  /// @dev Can only be called by a manager
  ///      Emit handled by {OpenZeppelin Pausable}
  function unpause() external virtual onlyManager {
    _unpause();
  }

  /// @notice Set contract URI
  /// @param contractUri contract URI for storefront level metadata
  function setContactURI(string memory contractUri) external virtual onlyManager {
    _contractUri = contractUri;

    emit ContractUriUpdated(contractUri);
  }

  /// @notice Set baseURI
  /// @param baseUri base URI for token metadata
  function setBaseURI(string memory baseUri) external virtual onlyManager {
    _baseTokenUri = baseUri;

    emit BaseUriUpdated(baseUri);
  }

  /// @dev Required override to enable operator filtering
  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  /// @dev Required override to enable operator filtering
  function approve(
    address to,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(to)
  {
    super.approve(to, tokenId);
  }

  /// @dev Required override to enable operator filtering
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  /// @dev Required override to enable operator filtering
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  /// @dev Required override to enable operator filtering
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  /// @notice Get base uri of tokens
  /// @dev Used to construct token uri
  /// @return string Uri
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenUri;
  }

  /// @dev Required override to enable transfer pausing
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /// @dev Required by the OpenZeppelin UUPS module
  function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

  /// @dev Required by solidity to describe the interface of the contract
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(AccessControlUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable)
    returns (bool)
  {
    return
      ERC721AUpgradeable.supportsInterface(interfaceId) ||
      AccessControlUpgradeable.supportsInterface(interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  /// @dev Storage gap for future upgrade-ability in inherited contracts
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./Errors.sol";

import "./IRoleAuthority.sol";
import "./IPosters.sol";

/**
 * @title Posters contract.
 * @notice The contract that manages the posters.
 * @author j6i, 0x-jj
 */
contract Posters is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC1155Upgradeable, IPosters {
  using StringsUpgradeable for uint256;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the RoleAuthority used to determine whether an address has some admin role.
   */
  IRoleAuthority public roleAuthority;

  /**
   * @notice The base uri for the token.
   */
  string public baseUri;

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializer called after contract creation.
   * @dev Can only be called once.
   * @param _roleAuthority The address of the RoleAuthority.
   * @param _baseUri The base uri for the token.
   */
  function initialize(address _roleAuthority, string calldata _baseUri) external initializer {
    __UUPSUpgradeable_init();
    __ERC1155_init("");
    __Ownable_init();
    roleAuthority = IRoleAuthority(_roleAuthority);
    baseUri = _baseUri;
  }

  /**
   * @dev Mint function to be called by minting module.
   * @param to The address to mint to.
   * @param id The token id to mint.
   * @param amount The amount to be minted.
   */
  function mint(address to, uint256 id, uint256 amount) external {
    if (!roleAuthority.isPosterMinter(msg.sender)) revert NotPosterMinter();

    _mint(to, id, amount, bytes(""));

    emit PosterMinted(to, id, amount);
  }

  /**
   * @dev Set the base uri.
   * @param _baseUri The base uri to set.
   */
  function setBaseUri(string calldata _baseUri) external {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
    baseUri = _baseUri;

    emit BaseUriSet(_baseUri);
  }

  /*//////////////////////////////////////////////////////////////
                                 PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev See {IERC1155-uri}.
   */
  function uri(uint256 id) public view override(ERC1155Upgradeable, IPosters) returns (string memory) {
    return string(abi.encodePacked(baseUri, id.toString()));
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev This is called as part of the UUPS upgrade process to ensure the upgrade is correctly permissioned
   */
  function _authorizeUpgrade(address) internal view override {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
  }
}

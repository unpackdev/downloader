// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./AccessControlDefaultAdminRulesUpgradeable.sol";

import "./IRoleAuthority.sol";

/**
 * @title Role authority for Deca collectibles.
 * @dev Used to manage admin roles for the Deca collectibles system.
 * @author 0x-jj
 */
contract RoleAuthority is Initializable, UUPSUpgradeable, AccessControlDefaultAdminRulesUpgradeable, IRoleAuthority {
  /**
   * @notice The `role` type used for approved operators.
   * @dev Operators can perform admin functions such as core contract upgrades and variable updates.
   * @return `keccak256("OPERATOR_ROLE")`
   */
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /**
   * @notice The `role` type used for approved minters of Deca Mint On Demand.
   * @return `keccak256("DECA_721_MINTER_ROLE")`
   */
  bytes32 public constant DECA_721_MINTER_ROLE = keccak256("DECA_721_MINTER_ROLE");

  /**
   * @notice The `role` type used for approved minters of Deca Posters.
   * @return `keccak256("DECA_POSTER_MINTER_ROLE")`
   */
  bytes32 public constant DECA_POSTER_MINTER_ROLE = keccak256("DECA_POSTER_MINTER_ROLE");

  /**
   * @notice The `role` type used to determine who can create valid mint passes.
   * @return `keccak256("MINT_PASS_SIGNER_ROLE")`
   */
  bytes32 public constant MINT_PASS_SIGNER_ROLE = keccak256("MINT_PASS_SIGNER_ROLE");

  /**
   * @notice The `role` type used to determine who can create valid posters.
   * @return `keccak256("POSTER_SIGNER_ROLE")`
   */
  bytes32 public constant POSTER_SIGNER_ROLE = keccak256("POSTER_SIGNER_ROLE");

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializer called after contract creation.
   * @dev Can only be called once.
   * @param admin The address of the admin.
   */
  function initialize(address admin) external initializer {
    __UUPSUpgradeable_init();
    __AccessControlDefaultAdminRules_init(3 days, admin);
    _grantRole(OPERATOR_ROLE, admin);
  }

  /**
   * @dev This is called as part of the UUPS upgrade process to ensure the upgrade is correctly permissioned
   */
  function _authorizeUpgrade(address) internal override onlyRole(OPERATOR_ROLE) {}

  /**
   * @notice Checks if the account provided is an operator.
   * @param account The address to check.
   * @return approved True if the account is an operator.
   */
  function isOperator(address account) external view returns (bool) {
    return hasRole(OPERATOR_ROLE, account);
  }

  /**
   * @notice Checks if the account provided is a minter of Deca Mint On Demand.
   * @param account The address to check.
   * @return approved True if the account is an minter of Deca Mint On Demand.
   */
  function is721Minter(address account) external view returns (bool) {
    return hasRole(DECA_721_MINTER_ROLE, account);
  }

  /**
   * @notice Checks if the account provided is a minter of Deca Posters.
   * @param account The address to check.
   * @return approved True if the account is an minter of Deca Posters.
   */
  function isPosterMinter(address account) external view returns (bool) {
    return hasRole(DECA_POSTER_MINTER_ROLE, account);
  }

  /**
   * @notice Checks if the account provided is a mint pass signer. Allows mints to be signed off chain and settled on chain.
   *         Signing allows us to provide gasless bid cancellations.
   * @param account The address to check.
   * @return approved True if the account is a mint pass signer.
   *
   */
  function isMintPassSigner(address account) external view returns (bool) {
    return hasRole(MINT_PASS_SIGNER_ROLE, account);
  }

  /**
   * @notice Checks if the provided account is authorized to sign the mint arguments for Deca Posters.
   * @param account The address to check.
   * @return approved True if the account is a poster signer.
   */
  function isPosterSigner(address account) external view returns (bool) {
    return hasRole(POSTER_SIGNER_ROLE, account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title ERC20Migrator
 * @dev This contract can be used to migrate an ERC20 token from one
 * contract to another, where each token holder has to opt-in to the migration.
 * To opt-in, users must approve for this contract the number of tokens they
 * want to migrate. Once the allowance is set up, anyone can trigger the
 * migration to the new token contract. In this way, token holders "turn in"
 * their old balance and will be minted an equal amount in the new token.
 * The new token contract must be mintable. For the precise interface refer to
 * OpenZeppelin's ERC20Mintable, but the only functions that are needed are
 * `isMinter(address)` and `mint(address, amount)`. The migrator will check
 * that it is a minter for the token.
 * The balance from the legacy token will be transfered to the migrator, as it
 * is migrated, and remain there forever.
 * Although this contract can be used in many different scenarios, the main
 * motivation was to provide a way to migrate ERC20 tokens into an upgradeable
 * version of it using ZeppelinOS. To read more about how this can be done
 * using this implementation, please follow the official documentation site of
 * ZeppelinOS: https://docs.zeppelinos.org/docs/erc20_onboarding.html
 * Example of usage:
 * ```
 * const migrator = await ERC20Migrator.new(legacyToken.address);
 * await newToken.addMinter(migrator.address);
 * await migrator.beginMigration(newToken.address);
 * ```
 */
contract Migrator is Ownable, Pausable {
  using SafeERC20 for IERC20;

  /// Address of the old token contract
  IERC20 private _legacyToken;

  /// Address of the new token contract
  IERC20 private _newToken;

  /**
   * @param legacyToken address of the old token contract
   */
  constructor(IERC20 legacyToken) {
    _legacyToken = legacyToken;
  }

  /**
   * @dev Returns the legacy token that is being migrated.
   */
  function getlegacyToken() external view returns (IERC20) {
    return _legacyToken;
  }

  /**
   * @dev Returns the new token to which we are migrating.
   */
  function getnewToken() external view returns (IERC20) {
    return _newToken;
  }

  /**
   * @dev Begins the migration by setting which is the new token that will be
   * minted. This contract must be a minter for the new token.
   * @param newToken the token that will be minted
   */
  function beginMigration(IERC20 newToken) external onlyOwner {
    _newToken = newToken;
  }

  /**
   * @dev Transfers part of an account's balance in the old token to this
   * contract, and mints the same amount of new tokens for that account.
   * @param account whose tokens will be migrated
   * @param amount amount of tokens to be migrated
   */
  function migrate(address account, uint256 amount) public {
    _beforeTokenTransfer();
    _legacyToken.safeTransferFrom(account, address(this), amount);
    _newToken.migrateMint(account, amount);
  }

  /**
   * @dev Transfers all of an account's allowed balance in the old token to
   * this contract, and mints the same amount of new tokens for that account.
   * @param account whose tokens will be migrated
   */
  function migrateAll(address account) external {
    _beforeTokenTransfer();
    uint256 balance = _legacyToken.balanceOf(account);
    uint256 allowance = _legacyToken.allowance(account, address(this));
    uint256 amount = Math.min(balance, allowance);
    migrate(account, amount);
  }

  /**
    * @dev Pause `contract` - pause events.
    *
    * See {BEP20Pausable-_pause}.
    */
  function pauseContract() external virtual onlyOwner {
      _pause();
  }
  
  /**
    * @dev Pause `contract` - pause events.
    *
    * See {BEP20Pausable-_pause}.
    */
  function unPauseContract() external virtual onlyOwner {
      _unpause();
  }

  /**
    * @dev Hook that is called before any transfer of tokens. This includes
    * minting and burning.
    *
    * Calling conditions:
    *
    * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    * will be to transferred to `to`.
    * - when `from` is zero, `amount` tokens will be minted for `to`.
    * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    * - `from` and `to` are never both zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
  function _beforeTokenTransfer() internal virtual { 
      require(!paused(), "ERC20Pausable: token transfer while contract paused");
  }
}
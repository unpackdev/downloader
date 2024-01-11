// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//                _             __   _____                               
//     /\        | |           / _| |  __ \                              
//    /  \   _ __| | __   ___ | |_  | |  | |_ __ ___  __ _ _ __ ___  ___ 
//   / /\ \ | '__| |/ /  / _ \|  _| | |  | | '__/ _ \/ _` | '_ ` _ \/ __|
//  / ____ \| |  |   <  | (_) | |   | |__| | | |  __/ (_| | | | | | \__ \
// /_/    \_\_|  |_|\_\  \___/|_|   |_____/|_|  \___|\__,_|_| |_| |_|___/
//
// Connecting your real world to the metaverse
// http://www.arkofdreams.io/
//

import "./ERC20BurnableUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";

import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

// ============ Errors ============

error InvalidCall();

// ============ Contract ============

contract ArkoniaToken is
  Initializable,
  ContextUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20CappedUpgradeable,
  UUPSUpgradeable
{
  // ============ Constants ============
  
  //all custom roles
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // ============ Deploy ============

  /**
   * @dev Sets the name and symbol. Sets the fixed supply.
   * Grants `DEFAULT_ADMIN_ROLE` to the specified admin.
   */
  function initialize(address admin) public initializer {
    __ERC20_init("Arkonia", "AOD");
    __ERC20Capped_init(1000000000 ether);

    __Context_init();
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    //set up roles for contract creator
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    //prevent unauthorized transfers
    _pause();
  }

  /**
   * @dev Required method for upgradeable contracts
   */
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

  // ============ Write Methods ============

  /**
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(
    address to, 
    uint256 amount
  ) external onlyRole(_MINTER_ROLE) {
    _mint(to, amount);
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() external onlyRole(_PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() external onlyRole(_PAUSER_ROLE) {
    _unpause();
  }

  // ============ Internal Methods ============

  /**
   * @dev Minters can mint even when paused
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    //if the sender is not a minter
    if (!hasRole(_MINTER_ROLE, _msgSender()) 
      //and is paused
      && paused()
    ) revert InvalidCall();

    super._beforeTokenTransfer(from, to, amount);
  }
}

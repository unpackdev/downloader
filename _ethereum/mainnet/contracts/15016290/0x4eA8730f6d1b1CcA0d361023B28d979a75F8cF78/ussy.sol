// SPDX-License-Identifier: MIT
// Founded date: 6/9/2022
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./MathUpgradeable.sol";

contract PulseUssyDegenerateDAO is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, ERC20CappedUpgradeable, OwnableUpgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  function initialize()
  public initializer
  {
    __ERC20_init("Pulse-ussy (Degenerate DAO)", "ussy");
    __ERC20Permit_init("Pulse-ussy (Degenerate DAO)");
    __ERC20Capped_init(696969696969);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(BURNER_ROLE, msg.sender);
    // bypasses cap check
    ERC20Upgradeable._mint(msg.sender, 69696969 * 10 ** decimals());
  }

  function mint(address to, uint256 amount)
  public onlyRole(MINTER_ROLE)
  {
    _mint(to, amount);
  }

  function decimals()
  public pure
  override(ERC20Upgradeable)
  returns (uint8)
  {
      return 2;
  }

  // The following functions are overrides required by Solidity.

  function _afterTokenTransfer(address from, address to, uint256 amount)
  internal
  override(ERC20Upgradeable, ERC20VotesUpgradeable)
  {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount)
  internal
  override(ERC20CappedUpgradeable, ERC20Upgradeable, ERC20VotesUpgradeable)
  {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
  internal
  override(ERC20Upgradeable, ERC20VotesUpgradeable)
  {
    super._burn(account, amount);
  }
}

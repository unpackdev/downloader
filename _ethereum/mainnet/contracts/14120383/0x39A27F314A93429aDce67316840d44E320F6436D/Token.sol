// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract JCR is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  struct IssuanceList {
    uint256[] time;
    uint256[] amount;
    string[] memo;
  }
  IssuanceList issuanceList;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(string memory name, string memory symbol) initializer public {
    __ERC20_init(name, symbol);
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(ISSUER_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);

    issuanceList.time = new uint256[](0);
    issuanceList.amount = new uint256[](0);
    issuanceList.memo = new string[](0);
  }

  function issue(address to, uint256 amount, string memory memo) public onlyRole(ISSUER_ROLE) {
    _mint(to, amount);
    issuanceList.time.push(block.timestamp);
    issuanceList.amount.push(amount);
    issuanceList.memo.push(memo);
  }

  function issuance() public view returns (IssuanceList memory) {
    return issuanceList;
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
      super._beforeTokenTransfer(from, to, amount);
    }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}
}

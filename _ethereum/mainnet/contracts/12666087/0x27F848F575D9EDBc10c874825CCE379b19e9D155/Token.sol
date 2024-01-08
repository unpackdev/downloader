//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract Token is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    ERC20SnapshotUpgradeable,
    ERC20PermitUpgradeable
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
    }

    //
    // Modifiers
    //
    modifier isGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Token: caller is not governor");
        _;
    }

    //
    // Admin functions
    //
    function pause() public virtual isGovernor() {
        _pause();
    }

    function unpause() public virtual isGovernor() {
        _unpause();
    }

    //
    // Customized ERC-20 functions
    //
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Token: must have minter role to mint");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20SnapshotUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

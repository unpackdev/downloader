// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

contract Reli is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function initialize(string memory name, string memory symbol) public virtual initializer {
        __Reli_init(name, symbol);

    }

    function __Reli_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __Reli_init_unchained(name, symbol);
    }

    function __Reli_init_unchained(string memory name, string memory symbol) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Reli: must have minter role to mint");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Reli: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Reli: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

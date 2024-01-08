// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract CapitalToken is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, PausableUpgradeable, ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256[50] private __gap;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function burn(uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }

    function initialize(address account, uint256 initialSupply) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained("Capital", "CPA");
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(MINTER_ROLE, account);
        _setupRole(PAUSER_ROLE, account);

        _mint(account, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function recoverToken(address tokenAddress, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(tokenAddress).safeTransfer(to, amount);
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        bool isAdminOrMinter = hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender());
        require(isAdminOrMinter || !paused(), "Capital: token transfer while paused");
    }
}

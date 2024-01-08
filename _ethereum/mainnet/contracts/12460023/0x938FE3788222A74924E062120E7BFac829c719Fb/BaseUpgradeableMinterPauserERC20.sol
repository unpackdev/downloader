//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./BaseUpgradeable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {PlatformSettings} and  {RolesManager} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract BaseUpgradeableMinterPauserERC20 is
    BaseUpgradeable,
    Initializable,
    ContextUpgradeable,
    ERC20BurnableUpgradeable
{
    function initialize(
        address settingsAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public virtual initializer {
        __ERC20PresetMinterPauser_init(settingsAddress, name, symbol, decimals);
    }

    function __ERC20PresetMinterPauser_init(
        address settingsAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal initializer {
        BaseUpgradeable.initialize(settingsAddress);
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        _setupDecimals(decimals);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public onlyMinter(_msgSender()) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

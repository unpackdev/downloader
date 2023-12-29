// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ERC20ETHlessTransfer.sol";
import "./ERC20Reservable.sol";
import "./ERC20Wrapper.sol";

/**
 * @dev Extension of {Gluwacoin} that allows a certain ERC20 token holders to wrap the token to mint this token.
 * Holder of this token can retrieve the wrapped token by burning this token.
 */
contract ERC20WrapperGluwacoin is
    Initializable,
    ContextUpgradeable,
    ERC20Wrapper,
    ERC20ETHless,
    ERC20Reservable
{
    uint8 private _decimals;

    /// @dev `decimals` must match that of `token`
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        address admin,
        IERC20Upgradeable token
    ) public virtual {
        __ERC20WrapperGluwacoin_init(name, symbol, decimals_, admin, token);
    }

    /// @notice Return a number of decimals of the token
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function __ERC20WrapperGluwacoin_init(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        address admin,
        IERC20Upgradeable token
    ) internal initializer {
        _decimals = decimals_;
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(token);
        __ERC20ETHless_init_unchained();
        __ERC20Reservable_init_unchained();
        __ERC20WrapperGluwacoin_init_unchained(decimals_, admin);
    }

    function __ERC20WrapperGluwacoin_init_unchained(
        uint8 decimals_,
        address admin
    ) internal onlyInitializing {
        _decimals = decimals_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20Reservable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";

/**
 * @title NNN Gold Token
 * @dev this contract is a Pausable ERC20 token with Burn and Mint functions.
 * By implementing EnhancedMinterPauser this contract also includes external
 * methods for setting a new implementation contract for the Proxy.
 * NOTE: All calls to this contract should be made through
 * the proxy, including admin actions.
 * Any call to transfer against this contract should fail.
 */
contract NVMToken is
    ERC20PresetMinterPauserUpgradeable,
    ERC20CappedUpgradeable
{
    function initializeNVM(uint256 cap) public initializer {
        __ERC20PresetMinterPauser_init("Novem Token", "NVM");
        __ERC20Capped_init_unchained(cap);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20CappedUpgradeable, ERC20Upgradeable)
    {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC20Upgradeable, ERC20PresetMinterPauserUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

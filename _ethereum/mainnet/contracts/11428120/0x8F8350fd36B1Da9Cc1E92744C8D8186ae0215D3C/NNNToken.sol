// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./EnhancedMinterPauser.sol";

/**
 * @title NNN Gold Token
 * @dev this contract is a Pausable ERC20 token with Burn and Mint functions.
 * By implementing EnhancedMinterPauser this contract also includes external
 * methods for setting a new implementation contract for the Proxy.
 * NOTE: All calls to this contract should be made through
 * the proxy, including admin actions.
 * Any call to transfer against this contract should fail.
 */
contract NNNToken is Initializable, EnhancedMinterPauser {
    function initialize(string memory name, string memory symbol)
        public
        override
        initializer
    {
        __ERC20_init_unchained(name, symbol);
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
        __EnhancedMinterPauser_init_unchained();
    }
}
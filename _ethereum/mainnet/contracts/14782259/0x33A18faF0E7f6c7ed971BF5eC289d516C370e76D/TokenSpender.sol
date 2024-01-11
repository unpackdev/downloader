// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./RegistryManager.sol";
import "./IRegistry.sol";

/**
    Error codes:
    - T1 = ERROR_TOKEN_SPENDER_NOT_WHITELISTED
 */

/// @title Opium.TokenSpender contract holds users ERC20 allowances and allows whitelisted contracts to use ERC20 tokens
contract TokenSpender is RegistryManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyCoreSpenders() {
        require(registry.isCoreSpenderWhitelisted(msg.sender), "T1");
        _;
    }

    /// @notice it is called only once upon deployment of the contract
    /// @param _registry sets the address of the Opium.Registry
    function initialize(address _registry) external initializer {
        __RegistryManager__init(_registry);
    }

    /// @notice Using this function whitelisted contracts could call ERC20 transfers
    /// @param _token IERC20 Instance of token
    /// @param _from address Address from which tokens are transferred
    /// @param _to address Address of tokens receiver
    /// @param _amount uint256 Amount of tokens to be transferred
    function claimTokens(
        IERC20Upgradeable _token,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyCoreSpenders {
        _token.safeTransferFrom(_from, _to, _amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

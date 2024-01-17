/*

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "./IERC20Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ProxyRegistry.sol";

contract TokenTransferProxy is ContextUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
    external
    returns (bool)
    {
        require(registry.contracts(_msgSender()), "Callers ProxyRegistry should be true");
        IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
        return true;
    }

}

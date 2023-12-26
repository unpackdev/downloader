// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice IUniversalVaultEvents interface
 * @dev Source: https://github.com/ampleforth/token-geyser-v2/blob/c878fd6ba5856d818ff41c54bce59c9413bc93c9/contracts/UniversalVault.sol#L20-L22
 */
interface IUniversalVaultEvents {
    /* user events */
    event Locked(address delegate, address token, uint256 amount);
    event Unlocked(address delegate, address token, uint256 amount);
    event RageQuit(address delegate, address token, bool notified, string reason);
}

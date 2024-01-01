// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

/**
 * @title A partial interface taken from the IDelegationRegistry provided under
 *  the CC0-1.0 Creative Commons license by delegate.xyz
 */
interface IDelegationRegistry {
    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault)
        external
        view
        returns (bool);
}

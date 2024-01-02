// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IEPMXToken {
    event WhitelistedAddressAdded(address indexed addr);
    event WhitelistedAddressRemoved(address indexed addr);
    event Burn(address indexed from, uint256 value);

    /**
     * @notice Adds the specified address to the whitelist.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _address The address to be added to the whitelist.
     */
    function addAddressToWhitelist(address _address) external;

    /**
     * @notice Adds multiple addresses to the whitelist.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _addresses The array of addresses to be added.
     */
    function addAddressesToWhitelist(address[] calldata _addresses) external;

    /**
     * @notice Removes an address from the whitelist.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _address The address to be removed.
     */
    function removeAddressFromWhitelist(address _address) external;

    /**
     * @notice Removes an address from the whitelist.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _addresses The array of addresses to be removed.
     */
    function removeAddressesFromWhitelist(address[] calldata _addresses) external;

    /**
     * @notice Burns a specific amount of tokens from the caller's balance.
     * @param _amount The amount of tokens to be burned.
     *
     * Requirements:
     * The caller must be on the white list.
     */
    function burn(uint256 _amount) external;

    /**
     * @notice Checks if an address is whitelisted.
     * @param _address The address to check.
     * @return A boolean value indicating whether the address is whitelisted or not.
     */
    function isWhitelisted(address _address) external view returns (bool);
}

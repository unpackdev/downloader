// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";

/**
 * @title IMTbill
 * @author RedDuck Software
 */
interface IMTbill is IERC20Upgradeable {
    /**
     * @notice mints mTBILL token `amount` to a given `to` address.
     * should be called only from permissioned actor
     * @param to addres to mint tokens to
     * @param amount amount to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice burns mTBILL token `amount` to a given `to` address.
     * should be called only from permissioned actor
     * @param from addres to burn tokens from
     * @param amount amount to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @notice updates contract`s metadata.
     * should be called only from permissioned actor
     * @param key metadata map. key
     * @param data metadata map. value
     */
    function setMetadata(bytes32 key, bytes memory data) external;

    /**
     * @notice puts mTBILL token on pause.
     * should be called only from permissioned actor
     */
    function pause() external;

    /**
     * @notice puts mTBILL token on pause.
     * should be called only from permissioned actor
     */
    function unpause() external;
}

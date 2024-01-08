// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IWhitelist {

    function addToWhitelist(address account) external;

    function removeFromWhitelist(address account) external;

    function isWhitelisted(address account) external view returns (bool);

    function addMinter(address account) external;

    function removeMinter(address account) external;
}
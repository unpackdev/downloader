// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the UpgradedStandardToken standard as defined in the EIP.
 */
interface IUpgradedStandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(
        address from,
        address to,
        uint256 value
    ) external;

    function transferFromByLegacy(
        address sender,
        address from,
        address spender,
        uint256 value
    ) external;

    function approveByLegacy(
        address from,
        address spender,
        uint256 value
    ) external;

    function balanceOf(address _owner) external view returns (uint256 balance);
}

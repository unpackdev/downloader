// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBaseCollection {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        string memory,
        string memory,
        address
    ) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}

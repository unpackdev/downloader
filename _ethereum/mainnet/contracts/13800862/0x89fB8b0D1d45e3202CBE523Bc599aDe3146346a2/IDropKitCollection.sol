// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

interface IDropKitCollection is
    IERC721Upgradeable,
    IERC721EnumerableUpgradeable
{
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(string memory, string memory, address) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}

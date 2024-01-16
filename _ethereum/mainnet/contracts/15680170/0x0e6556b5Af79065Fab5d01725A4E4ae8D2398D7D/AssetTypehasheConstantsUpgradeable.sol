// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetTypehasheConstantsUpgradeable
 * @author NeatFi
 * @notice This contract holds the typehashes for the protocol storage
 *         of NeatFi.
 */
contract AssetTypehasheConstantsUpgradeable is Initializable {
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(bytes32[] tokens,address maker,OrderType orderType,uint256 listingTime,uint256 expirationTime,uint256 startPrice,uint256 endPrice,bytes32 salt,Status status)"
        );

    bytes32 public constant TOKEN_TYPEHASH =
        keccak256(
            "Token(address tokenContract,uint256 tokenId,uint256 amount,TokenType tokenType)"
        );

    /* Initializers */

    function __AssetTypehasheConstants_init() internal initializer {
        __AssetTypehasheConstants_init_unchained();
    }

    function __AssetTypehasheConstants_init_unchained() internal initializer {}
}

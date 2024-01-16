// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetEnumsUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title AssetStructsUpgradeable
 * @author NeatFi
 * @notice This contract holds the structs for the protocol storage
 *         of NeatFi.
 */
contract AssetStructsUpgradeable is Initializable, AssetEnumsUpgradeable {
    /**
     * @dev The Order struct
     */
    struct Order {
        // Array containing Token hashes.
        bytes32[] tokenHashes;
        // Address of the maker.
        address payable maker;
        // Order type.
        AssetOrderType orderType;
        // Lsiting timestamp.
        uint256 listingTime;
        // Expiration timestamp.
        uint256 expirationTime;
        // Start price, set to 0 for SWAP orders.
        uint256 startPrice;
        // Price at Order filling.
        uint256 endPrice;
        // unique hash to ensure there will be no similar Order hashes.
        bytes32 salt;
        // Status of the Order.
        AssetOrderStatus status;
        // ActorKey of the Actor through which the Order was created.
        bytes32 actorKey;
    }

    /**
     * @dev The Token struct
     */
    struct Token {
        // Address of the Token contract.
        address tokenContract;
        // Array to hold Token ID for ERC721 and ERC1155 Token types, 0 for ERC20.
        uint256 tokenId;
        // Array to hold ERC20 and ERC1155 Token amount, 1 for ERC721.
        uint256 amount;
        // Token type.
        TokenType tokenType;
    }

    /* Initializers */

    function __AssetStructs_init() internal initializer {
        __AssetStructs_init_unchained();
        __AssetEnums_init();
    }

    function __AssetStructs_init_unchained() internal initializer {}
}

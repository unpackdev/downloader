// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetEnumsUpgradeable
 * @author NeatFi
 * @notice This contract holds the enums for the NeatFi assets.
 */
contract AssetEnumsUpgradeable is Initializable {
    enum AssetOrderType {
        // 0: Sell ERC20/721/1155 tokens for native currency (i.e. Eth, Matic, etc.).
        SELL,
        // 1: English Auction ERC20/721/1155 tokens for native currency (i.e. Eth, Matic, etc.).
        ENGLISH_AUCTION,
        // 2: Dutch Auction ERC20/721/1155 tokens for native currency (i.e. Eth, Matic, etc.).
        DUTCH_AUCTION,
        // 3: Swaps ERC20/721/1155 tokens with other ERC20/721/1155 tokens.
        SWAP,
        // 4: Bids ERC20/721/1155 tokens for a SELL, AUCTION, or SWAP order.
        BID
    }

    enum AssetOrderStatus {
        // 0: Order is open for interaction.
        OPEN,
        // 1: Order has accepted Bids and is unavailable for interaction.
        PROCESSING,
        // 2: Order has expired and is unavailable for interaction.
        EXPIRED,
        // 3: Order has been cancelled by the maker.
        CANCELLED,
        // 4: Order was successfully executed and an escrow was formed.
        CLOSED
    }

    enum TokenType {
        // 0: ERC721 token
        ERC721,
        // 1: ERC20 token
        ERC20,
        // 2: ERC1155 token
        ERC1155
    }

    /* Initializers */

    function __AssetEnums_init() internal initializer {
        __AssetEnums_init_unchained();
    }

    function __AssetEnums_init_unchained() internal initializer {}
}

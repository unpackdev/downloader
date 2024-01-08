// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ITransferProxy.sol";
import "./IERC2981Royalties.sol";

contract ExchangeStorage {
    enum TokenType {
        ETH,
        ERC20,
        ERC1155,
        ERC721
    }

    event Buy(
        uint256 indexed orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount,
        address maker,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyAmount,
        address buyer,
        uint256 total,
        uint256 serviceFee
    );

    event CloseOrder(
        uint256 orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        address maker
    );

    struct Asset {
        /* asset type, erc721 or erc1155 */
        TokenType tokenType;
        /* asset contract  */
        address token;
        /* asset id */
        uint256 tokenId;
        /* asset quantity */
        uint256 quantity;
    }

    struct OrderData {
        /* Exchange address - should be current contract */
        address exchange;
        /* maker of the order */
        address maker;
        /* taker of the order */
        address taker;
        /* out asset */
        Asset outAsset;
        /* in asset: this is the UNIT PRICE; which means amount bought must be multiplicated by quantity here */
        Asset inAsset;
        /* Max items by each buy. Allow to create one big order, but to limit how many can be bought at once */
        uint256 maxPerBuy;
        /* OrderNonce so we can have different order for the same tokenId */
        uint256 orderNonce;
        /* expiration date for this order - usually 1 month | 0 means never expires */
        uint256 expiration;
    }

    struct OrderMeta {
        /* buyer */
        address buyer;
        /* seller fee for the sale */
        uint256 sellerFee;
        /* buyer fee for the sale */
        uint256 buyerFee;
        /* expiration for this sale - usually 24h | 0 means never expires */
        uint256 expiration;
        /* Order Meta nonce so it can only be used once */
        uint256 nonce;
    }

    // signer used to sign "buys"
    // this allows to have buyer and sellerFee per tx and not global
    // this also allows to invalidate orders without needed them to be canceled
    // in the contract since a buy can't be done without being signed
    address public exchangeSigner;

    // To register saleMeta that were already used
    mapping(bytes32 => bool) public usedSaleMeta;

    // orderId => completed amount
    mapping(bytes32 => uint256) public completed;
}

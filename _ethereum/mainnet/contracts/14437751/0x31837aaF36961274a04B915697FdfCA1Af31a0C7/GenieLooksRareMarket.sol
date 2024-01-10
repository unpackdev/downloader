// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./Recoverable.sol";
import "./ArbitraryCall.sol";
import "./SendUtils.sol";

interface ILooksRareExchange {

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;
}

contract GenieLooksRareMarket is Recoverable, ArbitraryCall {

    address public constant LOOKSRARE_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    function buyAssetsForEth(
        ILooksRareExchange.TakerOrder[] calldata takerOrders,
        ILooksRareExchange.MakerOrder[] calldata makerOrders,
        address recipient
    ) external payable {
        for (uint256 i = 0; i < takerOrders.length; i++) {
            _buyAssetForEth(takerOrders[i], makerOrders[i], recipient);
        }
        SendUtils._returnAllEth();
    }

    function _buyAssetForEth(
        ILooksRareExchange.TakerOrder calldata takerOrder,
        ILooksRareExchange.MakerOrder calldata makerOrder,
        address recipient
    ) internal {
        try ILooksRareExchange(LOOKSRARE_EXCHANGE).matchAskWithTakerBidUsingETHAndWETH{value: takerOrder.price}(
            takerOrder,
            makerOrder
        ) {
            if (IERC165(makerOrder.collection).supportsInterface(IID_IERC721)) {
                IERC721(makerOrder.collection).transferFrom(address(this), recipient, makerOrder.tokenId);
            } else if (IERC165(makerOrder.collection).supportsInterface(IID_IERC1155)) {
                IERC1155(makerOrder.collection).safeTransferFrom(address(this), recipient, makerOrder.tokenId, makerOrder.amount, "0x");
            } else {
                revert("Unsupported interface");
            }
        } catch {}
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
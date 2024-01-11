// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "./LibCommonNftOrdersStorage.sol";
import "./LibERC1155OrdersStorage.sol";
import "./LibNFTOrder.sol";
import "./LibSignature.sol";
import "./NFTOrders.sol";
import "./IAuthenticatedProxy.sol";
import "./IProxyRegistry.sol";
import "./ISharedERC1155OrdersFeature.sol";


/// @dev Feature for interacting with ERC1155 orders.
contract ElementERC1155OrdersFeature is
    ISharedERC1155OrdersFeature,
    NFTOrders
{
    using LibNFTOrder for LibNFTOrder.ERC1155SellOrder;
    using LibNFTOrder for LibNFTOrder.ERC1155BuyOrder;
    using LibNFTOrder for LibNFTOrder.NFTSellOrder;
    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev User registry
    IProxyRegistry public immutable registry;

    constructor(IEtherToken weth, IProxyRegistry registryAddress) NFTOrders(weth) {
        registry = registryAddress;
    }

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellSharedERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes memory callbackData
    )
        public
        override
    {
        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                callbackData
            )
        );
    }

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes memory callbackData
    )
        public
        override
        payable
    {
        uint256 ethBalanceBefore = address(this).balance - msg.value;
        _buySharedERC1155(
            sellOrder,
            signature,
            BuyParams(
                erc1155BuyAmount,
                msg.value,
                taker,
                callbackData
            )
        );
       _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155FillAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuySharedERC1155s(
        LibNFTOrder.ERC1155SellOrder[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        address[] calldata takers,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    )
        public
        override
        payable
        returns (bool[] memory successes)
    {
        uint256 length = sellOrders.length;
        require(
            length == signatures.length &&
            length == takers.length &&
            length == erc1155FillAmounts.length &&
            length == callbackData.length,
            "ARRAY_LENGTH_MISMATCH"
        );
        successes = new bool[](length);

        uint256 ethBalanceBefore = address(this).balance - msg.value;
        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                // Will revert if _buySharedERC1155 reverts.
                _buySharedERC1155(
                    sellOrders[i],
                    signatures[i],
                    BuyParams(
                        erc1155FillAmounts[i],
                        address(this).balance - ethBalanceBefore, // Remaining ETH available
                        takers[i],
                        callbackData[i]
                    )
                );
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                // Delegatecall `_buySharedERC1155FromProxy` to catch swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this._buySharedERC1155FromProxy.selector,
                        sellOrders[i],
                        signatures[i],
                        BuyParams(
                            erc1155FillAmounts[i],
                            address(this).balance - ethBalanceBefore, // Remaining ETH available
                            takers[i],
                            callbackData[i]
                        )
                    )
                );
            }
        }

        // Refund
       _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    // @Note `_buySharedERC1155FromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function _buySharedERC1155FromProxy(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    )
        external
        payable
    {
        require(_implementation != address(this));
        _buySharedERC1155(sellOrder, signature, params);
    }

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellSharedERC1155` and `onERC1155Received`.
    function _sellERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    )
        private
    {
        (uint256 erc20FillAmount, bytes32 orderHash) = _sellNFT(
            buyOrder.asNFTBuyOrder(),
            signature,
            params
        );

        emit ERC1155BuyOrderFilled(
            buyOrder.maker,
            params.taker,
            (erc20FillAmount << 160) | uint160(address(buyOrder.erc20Token)),
            (params.tokenId << 160) | uint160(buyOrder.erc1155Token),
            params.sellAmount,
            orderHash
        );
    }

    function _buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    )
        internal
    {
        if (params.taker == address(0)) {
            params.taker = msg.sender;
        } else {
            require(params.taker != address(this), "_buy1155Ex/TAKER_CANNOT_SELF");
        }
        (uint256 erc20FillAmount, bytes32 orderHash) = _buyNFTEx(
            sellOrder.asNFTSellOrder(),
            signature,
            params
        );

        emit ERC1155SellOrderFilled(
            sellOrder.maker,
            msg.sender,
            (erc20FillAmount << 160) | uint160(address(sellOrder.erc20Token)),
            (sellOrder.erc1155TokenId << 160) | uint160(sellOrder.erc1155Token),
            params.buyAmount,
            orderHash
        );
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    )
        internal
        override
        view
    {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            require(
                LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned ==
                LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1,
                "PRESIGNED_INVALID_SIGNER"
            );
        } else {
            require(
                maker != address(0) && maker == ecrecover(orderHash, signature.v, signature.r, signature.s),
                "INVALID_SIGNER_ERROR"
            );
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        internal
        override
    {
        /* Retrieve delegateProxy contract. */
        IAuthenticatedProxy proxy = registry.proxies(from);

        /* Proxy must exist. */
        require(address(proxy) != address(0), "!delegateProxy");

        /* require implementation. */
        require(proxy.implementation() == registry.delegateProxyImplementation(), "!implementation");

        // 0xf242432a = keccak256(abi.encode(safeTransferFrom(address,address,uint256,uint256,bytes))
        bytes memory dataToCall = abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, "");
        require(proxy.proxy(token, 0, dataToCall), "!proxy call");
    }

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC1155 asset.
    /// @param buyOrder Order buying an ERC1155 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory sellOrderSignature,
        LibSignature.Signature memory buyOrderSignature
    )
        public
        override
        returns (uint256 profit)
    {
        // The ERC1155 tokens must match
        if (sellOrder.erc1155Token != buyOrder.erc1155Token) {
            revert("ERC1155_TOKEN_MISMATCH_ERROR");
        }

        LibNFTOrder.NFTSellOrder memory sellNFTOrder = sellOrder.asNFTSellOrder();
        LibNFTOrder.NFTBuyOrder memory buyNFTOrder = buyOrder.asNFTBuyOrder();
        LibNFTOrder.OrderInfo memory sellOrderInfo = _getOrderInfo(sellNFTOrder);
        LibNFTOrder.OrderInfo memory buyOrderInfo = _getOrderInfo(buyNFTOrder);

        bool isEnglishAuction = (sellOrder.expiry >> 252 == 2);
        if (isEnglishAuction) {
            require(
                sellOrderInfo.orderAmount == sellOrderInfo.remainingAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.orderAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.remainingAmount,
                "UNMATCH_ORDER_AMOUNT"
            );
        }

        _validateSellOrder(
            sellNFTOrder,
            sellOrderSignature,
            sellOrderInfo,
            buyOrder.maker
        );
        _validateBuyOrder(
            buyNFTOrder,
            buyOrderSignature,
            buyOrderInfo,
            sellOrder.maker,
            sellOrder.erc1155TokenId
        );

        // fillAmount = min(sellOrder.remainingAmount, buyOrder.remainingAmount)
        uint128 erc1155FillAmount = sellOrderInfo.remainingAmount < buyOrderInfo.remainingAmount ?
            sellOrderInfo.remainingAmount :
            buyOrderInfo.remainingAmount;
        // Reset sellOrder.erc20TokenAmount
        if (erc1155FillAmount != sellOrderInfo.orderAmount) {
            sellOrder.erc20TokenAmount = _ceilDiv(
                sellOrder.erc20TokenAmount * erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }
        // Reset buyOrder.erc20TokenAmount
        if (erc1155FillAmount != buyOrderInfo.orderAmount) {
            buyOrder.erc20TokenAmount =
                buyOrder.erc20TokenAmount * erc1155FillAmount / buyOrderInfo.orderAmount;
        }
        if (isEnglishAuction) {
            _resetEnglishAuctionTokenAmountAndFees(
                sellNFTOrder,
                buyOrder.erc20TokenAmount,
                erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }

        // Mark both orders as filled.
        _updateOrderState(sellNFTOrder, sellOrderInfo.orderHash, erc1155FillAmount);
        _updateOrderState(buyNFTOrder.asNFTSellOrder(), buyOrderInfo.orderHash, erc1155FillAmount);

        // The buyer must be willing to pay at least the amount that the
        // seller is asking.
        if (buyOrder.erc20TokenAmount < sellOrder.erc20TokenAmount) {
            revert("NEGATIVE_SPREAD_ERROR");
        }

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC1155 asset from seller to buyer.
        _transferNFTAssetFrom(
            address(sellOrder.erc1155Token),
            sellOrder.maker,
            buyOrder.maker,
            sellOrder.erc1155TokenId,
            erc1155FillAmount
        );

        // Handle the ERC20 side of the order:
        if (
            address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS &&
            buyOrder.erc20Token == WETH
        ) {
            // The sell order specifies ETH, while the buy order specifies WETH.
            // The orders are still compatible with one another, but we'll have
            // to unwrap the WETH on behalf of the buyer.

            // Step 1: Transfer WETH from the buyer to the EP.
            //         Note that we transfer `buyOrder.erc20TokenAmount`, which
            //         is the amount the buyer signaled they are willing to pay
            //         for the ERC1155 asset, which may be more than the seller's
            //         ask.
            _transferERC20TokensFrom(
                WETH,
                buyOrder.maker,
                address(this),
                buyOrder.erc20TokenAmount
            );
            // Step 2: Unwrap the WETH into ETH. We unwrap the entire
            //         `buyOrder.erc20TokenAmount`.
            //         The ETH will be used for three purposes:
            //         - To pay the seller
            //         - To pay fees for the sell order
            //         - Any remaining ETH will be sent to
            //           `msg.sender` as profit.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrder.maker), sellOrder.erc20TokenAmount);

            // Step 4: Pay fees for the buy order. Note that these are paid
            //         in _WETH_ by the _buyer_. By signing the buy order, the
            //         buyer signals that they are willing to spend a total
            //         of `erc20TokenAmount` _plus_ fees, all denominated in
            //         the `erc20Token`, which in this case is WETH.
            _payFees(
                buyNFTOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 5: Pay fees for the sell order. The `erc20Token` of the
            //         sell order is ETH, so the fees are paid out in ETH.
            //         There should be `spread` wei of ETH remaining in the
            //         EP at this point, which we will use ETH to pay the
            //         sell order fees.
            uint256 sellOrderFees = _payFees(
                sellNFTOrder,
                address(this), // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                true           // useNativeToken
            );

            // Step 6: The spread must be enough to cover the sell order fees.
            //         If not, either `_payFees` will have reverted, or we
            //         have spent ETH that was in the EP before this
            //         `matchSharedERC1155Orders` call, which we disallow.
            if (spread < sellOrderFees) {
                revert("SELL_ORDER_FEES_EXCEED_SPREAD");
            }
            // Step 7: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
               _transferEth(payable(msg.sender), profit);
            }
        } else {
            // ERC20 tokens must match
            if (sellOrder.erc20Token != buyOrder.erc20Token) {
                revert("ERC20_TOKEN_MISMATCH");
            }

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            //         Note that we transfer `sellOrder.erc20TokenAmount`, which
            //         is at most `buyOrder.erc20TokenAmount`.
            _transferERC20TokensFrom(
                buyOrder.erc20Token,
                buyOrder.maker,
                sellOrder.maker,
                sellOrder.erc20TokenAmount
            );

            // Step 2: Pay fees for the buy order. Note that these are paid
            //         by the buyer. By signing the buy order, the buyer signals
            //         that they are willing to spend a total of
            //         `buyOrder.erc20TokenAmount` _plus_ `buyOrder.fees`.
            _payFees(
                buyNFTOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 3: Pay fees for the sell order. These are paid by the buyer
            //         as well. After paying these fees, we may have taken more
            //         from the buyer than they agreed to in the buy order. If
            //         so, we revert in the following step.
            uint256 sellOrderFees = _payFees(
                sellNFTOrder,
                buyOrder.maker, // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 4: The spread must be enough to cover the sell order fees.
            //         If not, `_payFees` will have taken more tokens from the
            //         buyer than they had agreed to in the buy order, in which
            //         case we revert here.
            if (spread < sellOrderFees) {
                revert("SELL_ORDER_FEES_EXCEED_SPREAD");
            }

            // Step 5: We calculate the profit as:
            //         profit = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount - sellOrderFees
            //                = spread - sellOrderFees
            //         I.e. the buyer would've been willing to pay up to `profit`
            //         more to buy the asset, so instead that amount is sent to
            //         `msg.sender` as the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferERC20TokensFrom(
                    buyOrder.erc20Token,
                    buyOrder.maker,
                    msg.sender,
                    profit
                );
            }
        }

        _emitEventSellOrderFilled(
            sellOrder,
            buyOrder.maker, // taker
            erc1155FillAmount,
            sellOrderInfo.orderHash
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            sellOrder.maker, // taker
            sellOrder.erc1155TokenId,
            erc1155FillAmount,
            buyOrderInfo.orderHash
        );
    }

    function _emitEventSellOrderFilled(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        address taker,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) private {
        emit ERC1155SellOrderFilled(
            sellOrder.maker,
            taker,
            (sellOrder.erc20TokenAmount << 160) | uint160(address(sellOrder.erc20Token)),
            (sellOrder.erc1155TokenId << 160) | uint160(sellOrder.erc1155Token),
            erc1155FillAmount,
            orderHash
        );
    }

    function _emitEventBuyOrderFilled(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) private {
        emit ERC1155BuyOrderFilled(
            buyOrder.maker,
            taker,
            (buyOrder.erc20TokenAmount << 160) | uint160(address(buyOrder.erc20Token)),
            (erc1155TokenId << 160) | uint160(buyOrder.erc1155Token),
            erc1155FillAmount,
            orderHash
        );
    }

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC1155 assets.
    /// @param buyOrders Orders buying ERC1155 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchSharedERC1155Orders(
        LibNFTOrder.ERC1155SellOrder[] memory sellOrders,
        LibNFTOrder.ERC1155BuyOrder[] memory buyOrders,
        LibSignature.Signature[] memory sellOrderSignatures,
        LibSignature.Signature[] memory buyOrderSignatures
    )
        public
        override
        returns (uint256[] memory profits, bool[] memory successes)
    {
        require(
            sellOrders.length == buyOrders.length &&
            sellOrderSignatures.length == buyOrderSignatures.length &&
            sellOrders.length == sellOrderSignatures.length
        );
        profits = new uint256[](sellOrders.length);
        successes = new bool[](sellOrders.length);

        for (uint256 i = 0; i < sellOrders.length; i++) {
            bytes memory returnData;
            // Delegatecall `matchSharedERC1155Orders` to catch reverts while
            // preserving execution context.
            (successes[i], returnData) = _implementation.delegatecall(
                abi.encodeWithSelector(
                    this.matchSharedERC1155Orders.selector,
                    sellOrders[i],
                    buyOrders[i],
                    sellOrderSignatures[i],
                    buyOrderSignatures[i]
                )
            );
            if (successes[i]) {
                // If the matching succeeded, record the profit.
                (uint256 profit) = abi.decode(returnData, (uint256));
                profits[i] = profit;
            }
        }
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTSellOrder memory /* order */,
        bytes32 orderHash,
        uint128 fillAmount
    )
        internal
        override
    {
        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        uint128 filledAmount = stor.orderState[orderHash].filledAmount;
        // Filled amount should never overflow 128 bits
        require(filledAmount + fillAmount > filledAmount);
        stor.orderState[orderHash].filledAmount = filledAmount + fillAmount;
    }

    /// @dev Get the order info for an NFT sell order.
    /// @param nftSellOrder The NFT sell order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTSellOrder memory nftSellOrder)
        internal
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        LibNFTOrder.ERC1155SellOrder memory order = nftSellOrder.asERC1155SellOrder();
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = _getERC1155SellOrderHash(order);

        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.expiry & 0xffffffff00000000 > 0) {
            if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
                orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
                return orderInfo;
            }
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor =
                LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState =
                stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount - orderState.filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector =
                stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 ||
                orderCancellationBitVector & flag != 0)
            {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    /// @dev Get the order info for an NFT buy order.
    /// @param nftBuyOrder The NFT buy order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTBuyOrder memory nftBuyOrder)
        internal
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        LibNFTOrder.ERC1155BuyOrder memory order = nftBuyOrder.asERC1155BuyOrder();
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = _getERC1155BuyOrderHash(order);

        // Only buy orders with `erc1155TokenId` == 0 can be property
        // orders.
        if (order.erc1155TokenId != 0 && order.erc1155TokenProperties.length > 0) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (address(order.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.expiry & 0xffffffff00000000 > 0) {
            if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
                orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
                return orderInfo;
            }
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor =
                LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState =
                stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount - orderState.filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector =
                stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 ||
                orderCancellationBitVector & flag != 0)
            {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    function _getERC1155SellOrderHash(LibNFTOrder.ERC1155SellOrder memory order)
        private
        view
        returns (bytes32 orderHash)
    {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155SellOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }

    function _getERC1155BuyOrderHash(LibNFTOrder.ERC1155BuyOrder memory order)
        private
        view
        returns (bytes32 orderHash)
    {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155BuyOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }
}

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
import "./FixinEIP712.sol";
import "./FixinTokenSpender.sol";
import "./IEtherToken.sol";
import "./IFeeRecipient.sol";
import "./ITakerCallback.sol";
import "./IAuthenticatedProxy.sol";
import "./IProxyRegistry.sol";
import "./ISharedERC1155OrdersFeature.sol";

/// @dev Feature for interacting with ERC1155 orders.
contract ElementERC1155OrdersFeature is ISharedERC1155OrdersFeature, FixinEIP712, FixinTokenSpender {

    using LibNFTOrder for LibNFTOrder.ERC1155SellOrder;
    using LibNFTOrder for LibNFTOrder.ERC1155BuyOrder;
    using LibNFTOrder for LibNFTOrder.NFTSellOrder;
    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev Native token pseudo-address.
    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherToken internal immutable WETH;
    /// @dev The implementation address of this feature.
    address internal immutable _implementation;
    /// @dev User registry
    IProxyRegistry public immutable registry;

    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;
    /// @dev The magic return value indicating the success of a `zeroExTakerCallback`.
    bytes4 private constant TAKER_CALLBACK_MAGIC_BYTES = ITakerCallback.zeroExTakerCallback.selector;

    constructor(IEtherToken weth, IProxyRegistry registryAddress) {
        WETH = weth;
        registry = registryAddress;
        _implementation = address(this);
    }

    struct SellParams {
        uint128 sellAmount;
        uint256 tokenId;
        bool unwrapNativeToken;
        address taker;
        address currentNftOwner;
        bytes takerCallbackData;
        bytes metadata;
    }

    struct BuyParams {
        uint128 buyAmount;
        uint256 ethAvailable;
        address taker;
        bytes takerCallbackData;
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
        (bytes memory takerCallbackData, bytes memory metadata) = _getCallbackDataAndMetadata(callbackData);
        _sellSharedERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                takerCallbackData,
                metadata
            )
        );
    }

    function _getCallbackDataAndMetadata(bytes memory data) private pure returns (bytes memory takerCallbackData, bytes memory metadata) {
        if (data.length > 40) {
            // if start with "ipfs:","arweave","bzz-raw:", "filecoin", set the URI
            if ((data[0] == 0x69 && data[1] == 0x70 && data[2] == 0x66 && data[3] == 0x73) ||
                (data[0] == 0x61 && data[1] == 0x72 && data[2] == 0x77 && data[3] == 0x65) ||
                (data[0] == 0x62 && data[1] == 0x7a && data[2] == 0x7a && data[3] == 0x2d) ||
                (data[0] == 0x66 && data[1] == 0x69 && data[2] == 0x6c && data[3] == 0x65)) {
                return ("", data);
            }
        }
        return (data, "");
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
                // Delegatecall `buySharedERC1155FromProxy` to catch swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this.buySharedERC1155FromProxy.selector,
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

    // @Note `buySharedERC1155FromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function buySharedERC1155FromProxy(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _buySharedERC1155(sellOrder, signature, params);
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
        require(sellOrder.erc1155Token == buyOrder.erc1155Token, "ERC1155_TOKEN_MISMATCH_ERROR");

        LibNFTOrder.OrderInfo memory sellOrderInfo = _getOrderInfo(sellOrder);
        LibNFTOrder.OrderInfo memory buyOrderInfo = _getOrderInfo(buyOrder);

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
            sellOrder,
            sellOrderSignature,
            sellOrderInfo,
            buyOrder.maker
        );
        _validateBuyOrder(
            buyOrder,
            buyOrderSignature,
            buyOrderInfo,
            sellOrder.maker,
            sellOrder.erc1155TokenId
        );

        // fillAmount = min(sellOrder.remainingAmount, buyOrder.remainingAmount)
        uint128 erc1155FillAmount = sellOrderInfo.remainingAmount < buyOrderInfo.remainingAmount ?
            sellOrderInfo.remainingAmount : buyOrderInfo.remainingAmount;
        // Reset sellOrder.erc20TokenAmount
        if (erc1155FillAmount != sellOrderInfo.orderAmount) {
            sellOrder.erc20TokenAmount = _ceilDiv(sellOrder.erc20TokenAmount * erc1155FillAmount, sellOrderInfo.orderAmount);
        }
        // Reset buyOrder.erc20TokenAmount
        if (erc1155FillAmount != buyOrderInfo.orderAmount) {
            buyOrder.erc20TokenAmount = buyOrder.erc20TokenAmount * erc1155FillAmount / buyOrderInfo.orderAmount;
        }
        if (isEnglishAuction) {
            _resetEnglishAuctionTokenAmountAndFees(
                sellOrder,
                buyOrder.erc20TokenAmount,
                erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }

        // Mark both orders as filled.
        _updateOrderState(sellOrderInfo.orderHash, erc1155FillAmount);
        _updateOrderState(buyOrderInfo.orderHash, erc1155FillAmount);

        // The buyer must be willing to pay at least the amount that the
        // seller is asking.
        require(buyOrder.erc20TokenAmount >= sellOrder.erc20TokenAmount, "NEGATIVE_SPREAD_ERROR");

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC1155 asset from seller to buyer.
        _transferNFTAsset(sellOrder, buyOrder.maker, erc1155FillAmount);

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
                buyOrder.asNFTBuyOrder().asNFTSellOrder(),
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
                sellOrder.asNFTSellOrder(),
                address(this), // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                true           // useNativeToken
            );

            // Step 6: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferEth(payable(msg.sender), profit);
            }
        } else {
            // ERC20 tokens must match
            require(sellOrder.erc20Token == buyOrder.erc20Token, "ERC20_TOKEN_MISMATCH");

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
                buyOrder.asNFTBuyOrder().asNFTSellOrder(),
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
                sellOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 4: We calculate the profit as:
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
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
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
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            buyOrder.erc1155Token,
            erc1155TokenId,
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

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellSharedERC1155` and `onERC1155Received`.
    function _sellSharedERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(buyOrder);

        // Check that the order can be filled.
        _validateBuyOrder(buyOrder, signature, orderInfo, params.taker, params.tokenId);

        // Check amount.
        require(params.sellAmount <= orderInfo.remainingAmount, "_sell/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(orderInfo.orderHash, params.sellAmount);

        // Calculate erc20 pay amount.
        uint256 erc20FillAmount = (params.sellAmount == orderInfo.orderAmount) ?
            buyOrder.erc20TokenAmount : buyOrder.erc20TokenAmount * params.sellAmount / orderInfo.orderAmount;

        if (params.unwrapNativeToken) {
            // The ERC20 token must be WETH for it to be unwrapped.
            require(buyOrder.erc20Token == WETH, "_sell/ERC20_TOKEN_MISMATCH_ERROR");

            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            // TODO: Probably safe to just use WETH.transferFrom for some
            //       small gas savings
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), erc20FillAmount);

            // Unwrap WETH into ETH.
            WETH.withdraw(erc20FillAmount);

            // Send ETH to the seller.
            _transferEth(payable(params.taker), erc20FillAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, params.taker, erc20FillAmount);
        }

        if (params.takerCallbackData.length > 0) {
            require(params.taker != address(this), "_sell/CANNOT_CALLBACK_SELF");

            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(params.taker).zeroExTakerCallback(orderInfo.orderHash, params.takerCallbackData);

            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "_sell/CALLBACK_FAILED");
        }

        // Transfer the ERC1155 asset to the buyer.
        _transferNFTAsset(buyOrder, params);

        // The buyer pays the order fees.
        LibNFTOrder.NFTSellOrder memory order;
        assembly { order := buyOrder }
        _payFees(order, buyOrder.maker, params.sellAmount, orderInfo.orderAmount, false);

        emit ERC1155BuyOrderFilled(
            buyOrder.maker,
            params.taker,
            buyOrder.erc20Token,
            erc20FillAmount,
            buyOrder.erc1155Token,
            params.tokenId,
            params.sellAmount,
            orderInfo.orderHash
        );
    }

    function _buySharedERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) internal {
        if (params.taker == address(0)) {
            params.taker = msg.sender;
        } else {
            require(params.taker != address(this), "_buy/TAKER_CANNOT_SELF");
        }

        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(sellOrder);

        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, params.taker);

        // Check amount.
        require(params.buyAmount <= orderInfo.remainingAmount, "_buy/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(orderInfo.orderHash, params.buyAmount);

        // Dutch Auction
        if (sellOrder.expiry >> 252 == 1) {
            uint256 count = (sellOrder.expiry >> 64) & 0xffffffff;
            if (count > 0) {
                _resetDutchAuctionTokenAmountAndFees(sellOrder, count);
            }
        }

        // Calculate erc20 pay amount.
        uint256 erc20FillAmount = (params.buyAmount == orderInfo.orderAmount) ?
            sellOrder.erc20TokenAmount : _ceilDiv(sellOrder.erc20TokenAmount * params.buyAmount, orderInfo.orderAmount);

        // Transfer the ERC1155 asset to the buyer.
        _transferNFTAsset(sellOrder, params.taker, params.buyAmount);

        uint256 ethAvailable = params.ethAvailable;
        if (params.takerCallbackData.length > 0) {
            require(params.taker != address(this), "_buy/CANNOT_CALLBACK_SELF");

            uint256 ethBalanceBeforeCallback = address(this).balance;

            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(params.taker).zeroExTakerCallback(orderInfo.orderHash, params.takerCallbackData);

            // Update `ethAvailable` with amount acquired during
            // the callback
            ethAvailable += address(this).balance - ethBalanceBeforeCallback;

            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "_buy/CALLBACK_FAILED");
        }

        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            uint256 totalPaid = erc20FillAmount + _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable < totalPaid) {
                // Transfer WETH from the buyer to this contract.
                uint256 withDrawAmount = totalPaid - ethAvailable;
                _transferERC20TokensFrom(WETH, msg.sender, address(this), withDrawAmount);

                // Unwrap WETH into ETH.
                WETH.withdraw(withDrawAmount);
            }

            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
        } else if (sellOrder.erc20Token == WETH) {
            uint256 totalFeesPaid = _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable > totalFeesPaid) {
                uint256 depositAmount = ethAvailable - totalFeesPaid;
                if (depositAmount < erc20FillAmount) {
                    // Transfer WETH from the buyer to this contract.
                    _transferERC20TokensFrom(WETH, msg.sender, address(this), (erc20FillAmount - depositAmount));
                } else {
                    depositAmount = erc20FillAmount;
                }

                // Wrap ETH.
                WETH.deposit{value: depositAmount}();

                // Transfer WETH to the seller.
                _transferERC20Tokens(WETH, sellOrder.maker, erc20FillAmount);

                // Fees are paid from the EP's current balance of ETH.
                _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
            } else {
                // Transfer WETH from the buyer to the seller.
                _transferERC20TokensFrom(WETH, msg.sender, sellOrder.maker, erc20FillAmount);

                if (ethAvailable > 0) {
                    if (ethAvailable < totalFeesPaid) {
                        // Transfer WETH from the buyer to this contract.
                        uint256 value = totalFeesPaid - ethAvailable;
                        _transferERC20TokensFrom(WETH, msg.sender, address(this), value);

                        // Unwrap WETH into ETH.
                        WETH.withdraw(value);
                    }

                    // Fees are paid from the EP's current balance of ETH.
                    _payFees(sellOrder.asNFTSellOrder(), address(this), params.buyAmount, orderInfo.orderAmount, true);
                } else {
                    // The buyer pays fees using WETH.
                    _payFees(sellOrder.asNFTSellOrder(), msg.sender, params.buyAmount, orderInfo.orderAmount, false);
                }
            }
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);

            // The buyer pays fees.
            _payFees(sellOrder.asNFTSellOrder(), msg.sender, params.buyAmount, orderInfo.orderAmount, false);
        }

        emit ERC1155SellOrderFilled(
            sellOrder.maker,
            msg.sender,
            sellOrder.erc20Token,
            erc20FillAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            params.buyAmount,
            orderInfo.orderHash
        );
    }

    function _transferNFTAsset(LibNFTOrder.ERC1155BuyOrder memory order, SellParams memory params) private {
        _transferNFTAssetFrom(order.erc1155Token, params.currentNftOwner, order.maker, params.tokenId, params.sellAmount, params.metadata);
    }

    function _transferNFTAsset(LibNFTOrder.ERC1155SellOrder memory order, address to, uint256 amount) private {
        bytes memory data;
        for (uint256 i = 0; i < order.fees.length; i++) {
            if (order.fees[i].recipient == address(0)) {
                data = order.fees[i].feeData;
                break;
            }
        }
        _transferNFTAssetFrom(order.erc1155Token, order.maker, to, order.erc1155TokenId, amount, data);
    }

    function _transferNFTAssetFrom(address token, address from, address to, uint256 tokenId, uint256 amount, bytes memory data) private {
        /* Retrieve delegateProxy contract. */
        IAuthenticatedProxy proxy = registry.proxies(from);

        /* Proxy must exist. */
        require(address(proxy) != address(0), "!delegateProxy");

        /* require implementation. */
        require(proxy.implementation() == registry.delegateProxyImplementation(), "!implementation");

        // 0xf242432a = keccak256(abi.encode(safeTransferFrom(address,address,uint256,uint256,bytes))
        bytes memory dataToCall = abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, data);
        require(proxy.proxy(token, 0, dataToCall), "!proxy call");
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
    ) internal view {
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

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(bytes32 orderHash, uint128 fillAmount) internal {
        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        uint128 filledAmount = stor.orderState[orderHash].filledAmount;
        // Filled amount should never overflow 128 bits
        require(filledAmount + fillAmount > filledAmount);
        stor.orderState[orderHash].filledAmount = filledAmount + fillAmount;
    }

    function _getOrderInfo(LibNFTOrder.ERC1155SellOrder memory order) internal view returns (LibNFTOrder.OrderInfo memory orderInfo) {
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

    function _getOrderInfo(LibNFTOrder.ERC1155BuyOrder memory order) internal view returns (LibNFTOrder.OrderInfo memory orderInfo) {
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

    function _getERC1155SellOrderHash(LibNFTOrder.ERC1155SellOrder memory order) private view returns (bytes32 orderHash) {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155SellOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }

    function _getERC1155BuyOrderHash(LibNFTOrder.ERC1155BuyOrder memory order) private view returns (bytes32 orderHash) {
        return _getEIP712Hash(
            LibNFTOrder.getERC1155BuyOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
            )
        );
    }

    function _validateSellOrder(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker
    ) internal view {
        // Taker must match the order taker, if one is specified.
        require(sellOrder.taker == address(0) || sellOrder.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, sellOrder.maker);
    }

    function _validateBuyOrder(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker,
        uint256 tokenId
    ) internal view {
        // The ERC20 token cannot be ETH.
        require(address(buyOrder.erc20Token) != NATIVE_TOKEN_ADDRESS, "_validateBuyOrder/TOKEN_MISMATCH");

        // Taker must match the order taker, if one is specified.
        require(buyOrder.taker == address(0) || buyOrder.taker == taker, "_validateBuyOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check that the asset with the given token ID satisfies the properties
        // specified by the order.
        _validateOrderProperties(buyOrder, tokenId);

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, buyOrder.maker);
    }

    function _resetDutchAuctionTokenAmountAndFees(LibNFTOrder.ERC1155SellOrder memory order, uint256 count) internal view {
        require(count <= 100000000, "COUNT_OUT_OF_SIDE");

        uint256 listingTime = (order.expiry >> 32) & 0xffffffff;
        uint256 denominator = ((order.expiry & 0xffffffff) - listingTime) * 100000000;
        uint256 multiplier = (block.timestamp - listingTime) * count;

        // Reset erc20TokenAmount
        uint256 amount = order.erc20TokenAmount;
        order.erc20TokenAmount = amount - amount * multiplier / denominator;

        // Reset fees
        for (uint256 i = 0; i < order.fees.length; i++) {
            amount = order.fees[i].amount;
            order.fees[i].amount = amount - amount * multiplier / denominator;
        }
    }

    function _resetEnglishAuctionTokenAmountAndFees(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        uint256 buyERC20Amount,
        uint256 fillAmount,
        uint256 orderAmount
    ) internal pure {
        uint256 sellOrderFees = _calcTotalFeesPaid(sellOrder.fees, fillAmount, orderAmount);
        uint256 sellTotalAmount = sellOrderFees + sellOrder.erc20TokenAmount;
        if (buyERC20Amount != sellTotalAmount) {
            uint256 spread = buyERC20Amount - sellTotalAmount;
            uint256 sum;

            // Reset fees
            if (sellTotalAmount > 0) {
                for (uint256 i = 0; i < sellOrder.fees.length; i++) {
                    uint256 diff = spread * sellOrder.fees[i].amount / sellTotalAmount;
                    sellOrder.fees[i].amount += diff;
                    sum += diff;
                }
            }

            // Reset erc20TokenAmount
            sellOrder.erc20TokenAmount += spread - sum;
        }
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }

    function _calcTotalFeesPaid(LibNFTOrder.Fee[] memory fees, uint256 fillAmount, uint256 orderAmount) private pure returns (uint256 totalFeesPaid) {
        if (fillAmount == orderAmount) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount;
            }
        } else {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount * fillAmount / orderAmount;
            }
        }
        return totalFeesPaid;
    }

    function _payFees(
        LibNFTOrder.NFTSellOrder memory order,
        address payer,
        uint128 fillAmount,
        uint128 orderAmount,
        bool useNativeToken
    ) internal returns (uint256 totalFeesPaid) {
        for (uint256 i = 0; i < order.fees.length; i++) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            if (fee.recipient == address(0)) {
                require(fee.amount == 0, "_payFees/FEE.AMOUNT_ERROR");
                continue;
            }

            uint256 feeFillAmount = (fillAmount == orderAmount) ? fee.amount : fee.amount * fillAmount / orderAmount;

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                if (feeFillAmount > 0) {
                    // Transfer ERC20 token from payer to recipient.
                    _transferERC20TokensFrom(order.erc20Token, payer, fee.recipient, feeFillAmount);
                }
            }

            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(order.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );

                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "_payFees/CALLBACK_FAILED");
            }

            // Sum the fees paid
            totalFeesPaid += feeFillAmount;
        }
        return totalFeesPaid;
    }

    function _validateOrderProperties(LibNFTOrder.ERC1155BuyOrder memory order, uint256 tokenId) internal view {
        // If no properties are specified, check that the given
        // `tokenId` matches the one specified in the order.
        if (order.erc1155TokenProperties.length == 0) {
            require(tokenId == order.erc1155TokenId, "_validateProperties/TOKEN_ID_ERR");
        } else {
            // Validate each property
            for (uint256 i = 0; i < order.erc1155TokenProperties.length; i++) {
                LibNFTOrder.Property memory property = order.erc1155TokenProperties[i];
                // `address(0)` is interpreted as a no-op. Any token ID
                // will satisfy a property with `propertyValidator == address(0)`.
                if (address(property.propertyValidator) != address(0)) {
                    // Call the property validator and throw a descriptive error
                    // if the call reverts.
                    try property.propertyValidator.validateProperty(order.erc1155Token, tokenId, property.propertyData) {
                    } catch (bytes memory /* reason */) {
                        revert("PROPERTY_VALIDATION_FAILED");
                    }
                }
            }
        }
    }
}

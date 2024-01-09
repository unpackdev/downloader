pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";
import "./LibValidator.sol";
import "./LibExchange.sol";
import "./LibUnitConverter.sol";
import "./SafeTransferHelper.sol";
import "./IPoolFunctionality.sol";

library LibPool {

    function updateFilledAmount(
        LibValidator.Order memory order,
        uint112 filledBase,
        mapping(bytes32 => uint192) storage filledAmounts
    ) internal {
        bytes32 orderHash = LibValidator.getTypeValueHash(order);
        uint192 total_amount = filledAmounts[orderHash];
        total_amount += filledBase; //it is safe to add ui112 to each other to get i192
        require(total_amount >= filledBase, "E12B_0");
        require(total_amount <= order.amount, "E12B");
        filledAmounts[orderHash] = total_amount;
    }

    function refundChange(uint amountOut) internal {
        uint actualOutBaseUnit = uint(LibUnitConverter.decimalToBaseUnit(address(0), amountOut));
        if (msg.value > actualOutBaseUnit) {
            SafeTransferHelper.safeTransferTokenOrETH(address(0), msg.sender, msg.value - actualOutBaseUnit);
        }
    }

    function doSwapThroughOrionPool(
        uint112     amount_spend,
        uint112     amount_receive,
        address[] calldata   path,
        bool        is_exact_spend,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        address orionpoolRouter
    ) public returns(bool) {
        bool isInContractTrade = assetBalances[msg.sender][path[0]] > 0;
        bool isSentETHEnough;
        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (path[0] == address(0) && eth_sent >= amount_spend) {
                isSentETHEnough = true;
                isInContractTrade = false;
            } else {
                LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
            }
        }

        (uint amountOut, uint amountIn) = IPoolFunctionality(orionpoolRouter).doSwapThroughOrionPool(
            isInContractTrade || isSentETHEnough ? address(this) : msg.sender,
            amount_spend,
            amount_receive,
            path,
            is_exact_spend,
            isInContractTrade ? address(this) : msg.sender
        );

        if (isSentETHEnough) {
            refundChange(amountOut);
        } else if (isInContractTrade) {
            LibExchange._updateBalance(msg.sender, path[0], -1*int256(amountOut), assetBalances, liabilities);
            LibExchange._updateBalance(msg.sender, path[path.length-1], int(amountIn), assetBalances, liabilities);
            return true;
        }

        return false;
    }

    //  Just to avoid stack too deep error;
    struct OrderExecutionData {
        uint filledBase;
        uint filledQuote;
        uint filledPrice;
        uint amount_spend;
        uint amount_receive;
        uint amountQuote;
        bool isInContractTrade;
        bool isRetainFee;
        address to;
    }

    function calcAmounts(
        LibValidator.Order memory order,
        uint112 filledAmount,
        address[] calldata path,
        mapping(address => mapping(address => int192)) storage assetBalances
    ) internal returns (OrderExecutionData memory tmp) {
        tmp.amountQuote = uint(filledAmount) * order.price / (10**8);
        (tmp.amount_spend, tmp.amount_receive) = order.buySide == 0 ? (uint(filledAmount), tmp.amountQuote)
            : (tmp.amountQuote, uint(filledAmount));

        tmp.isInContractTrade = path[0] == address(0) || assetBalances[order.senderAddress][path[0]] > 0;
        tmp.isRetainFee = !tmp.isInContractTrade && order.matcherFeeAsset == path[path.length-1];

        tmp.to = (tmp.isInContractTrade || tmp.isRetainFee) ? address(this) : order.senderAddress;
    }

    function calcAmountInOutAfterSwap(
        OrderExecutionData memory tmp,
        LibValidator.Order memory order,
        uint64 blockchainFee,
        address[] calldata path,
        uint amountOut,
        uint amountIn,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        bool isSeller = order.buySide == 0;

        (tmp.filledBase, tmp.filledQuote) = isSeller ? (amountOut, amountIn) : (amountIn, amountOut);
        tmp.filledPrice = tmp.filledQuote * (10**8) / tmp.filledBase;

        if (isSeller) {
            require(tmp.filledPrice >= order.price, "EX");
        } else {
            require(tmp.filledPrice <= order.price, "EX");
        }

        //  Change fee only after order validation
        if (blockchainFee < order.matcherFee)
            order.matcherFee = blockchainFee;

        if (tmp.isInContractTrade) {
            (uint tradeType, int actualIn) = LibExchange.updateOrderBalanceDebit(order, uint112(tmp.filledBase),
                uint112(tmp.filledQuote), isSeller ? LibExchange.kSell : LibExchange.kBuy, assetBalances, liabilities);
            LibExchange.creditUserAssets(tradeType, order.senderAddress, actualIn, path[path.length-1], assetBalances, liabilities);

        } else {
            _payMatcherFee(order, assetBalances, liabilities);
            if (tmp.isRetainFee) {
                LibExchange.creditUserAssets(1, order.senderAddress, int(amountIn), path[path.length-1], assetBalances, liabilities);
            }
        }
    }

    function doFillThroughOrionPool(
        LibValidator.Order memory order,
        uint112 filledAmount,
        uint64 blockchainFee,
        address[] calldata path,
        address allowedMatcher,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        address orionpoolRouter,
        mapping(bytes32 => uint192) storage filledAmounts
    ) public returns (OrderExecutionData memory tmp){

        LibValidator.checkOrderSingleMatch(order, msg.sender, allowedMatcher, filledAmount, block.timestamp, path);
        bool isSeller = order.buySide == 0;

        tmp = calcAmounts(order, filledAmount, path, assetBalances);

        try IPoolFunctionality(orionpoolRouter).doSwapThroughOrionPool(
            tmp.isInContractTrade ? address(this) : order.senderAddress,
            uint112(tmp.amount_spend),
            uint112(tmp.amount_receive),
            path,
            isSeller,
            tmp.to
        ) returns(uint amountOut, uint amountIn) {
            calcAmountInOutAfterSwap(tmp, order, blockchainFee, path, amountOut, amountIn, assetBalances, liabilities);
        } catch(bytes memory) {
            tmp.filledBase = 0;
            tmp.filledPrice = order.price;
            _payMatcherFee(order, assetBalances, liabilities);
        }

        updateFilledAmount(order, uint112(tmp.filledBase), filledAmounts);
    }

    function _payMatcherFee(
        LibValidator.Order memory order,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        LibExchange._updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int(order.matcherFee), assetBalances, liabilities);
        LibExchange._updateBalance(order.matcherAddress, order.matcherFeeAsset, int(order.matcherFee), assetBalances, liabilities);
    }

}

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

    struct SwapData {
        uint112     amount_spend;
        uint112     amount_receive;
        bool        is_exact_spend;
        address[]   path;
        address     orionpool_router;
        bool        isInContractTrade;
        bool        isSentETHEnough;
        address     asset_spend;
    }

    function retrieveAssetSpend(address pf, address[] memory path) internal view returns (address) {
        return path.length > 2 ? (IPoolFunctionality(pf).isFactory(path[0]) ? path[1] : path[0]) : path[0];
    }

    function doSwapThroughOrionPool(
        SwapData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(bool) {
        d.asset_spend = retrieveAssetSpend(d.orionpool_router, d.path);
        d.isInContractTrade = assetBalances[msg.sender][d.asset_spend] > 0;

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (d.asset_spend == address(0) && eth_sent >= d.amount_spend) {
                d.isSentETHEnough = true;
                d.isInContractTrade = false;
            } else {
                LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
            }
        }

        (uint amountOut, uint amountIn) = IPoolFunctionality(d.orionpool_router).doSwapThroughOrionPool(
            d.isInContractTrade || d.isSentETHEnough ? address(this) : msg.sender,
            d.amount_spend,
            d.amount_receive,
            d.path,
            d.is_exact_spend,
            d.isInContractTrade ? address(this) : msg.sender
        );

        if (d.isSentETHEnough) {
            refundChange(amountOut);
        } else if (d.isInContractTrade) {
            LibExchange._updateBalance(msg.sender, d.asset_spend, -1*int256(amountOut), assetBalances, liabilities);
            LibExchange._updateBalance(msg.sender, d.path[d.path.length-1], int(amountIn), assetBalances, liabilities);
            return true;
        }

        return false;
    }

    //  Just to avoid stack too deep error;
    struct OrderExecutionData {
        LibValidator.Order order;
        uint filledAmount;
        uint blockchainFee;
        address[] path;
        address allowedMatcher;
        address orionpoolRouter;
        uint amount_spend;
        uint amount_receive;
        uint amountQuote;
        uint filledBase;
        uint filledQuote;
        uint filledPrice;
        bool isInContractTrade;
        bool isRetainFee;
        address to;
        address asset_spend;
    }

    function calcAmounts(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances
    ) internal {
        d.amountQuote = uint(d.filledAmount) * d.order.price / (10**8);
        (d.amount_spend, d.amount_receive) = d.order.buySide == 0 ? (uint(d.filledAmount), d.amountQuote)
            : (d.amountQuote, uint(d.filledAmount));

        d.asset_spend = retrieveAssetSpend(d.orionpoolRouter, d.path);
        d.isInContractTrade = d.asset_spend == address(0) || assetBalances[d.order.senderAddress][d.asset_spend] > 0;
        d.isRetainFee = !d.isInContractTrade && d.order.matcherFeeAsset == d.path[d.path.length-1];

        d.to = (d.isInContractTrade || d.isRetainFee) ? address(this) : d.order.senderAddress;
    }

    function calcAmountInOutAfterSwap(
        OrderExecutionData memory d,
        uint amountOut,
        uint amountIn,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {

        (d.filledBase, d.filledQuote) = d.order.buySide == 0 ? (amountOut, amountIn) : (amountIn, amountOut);
        d.filledPrice = d.filledQuote * (10**8) / d.filledBase;

        if (d.order.buySide == 0) {
            require(d.filledPrice >= d.order.price, "EX");
        } else {
            require(d.filledPrice <= d.order.price, "EX");
        }

        //  Change fee only after order validation
        if (d.blockchainFee < d.order.matcherFee)
            d.order.matcherFee = uint64(d.blockchainFee);

        if (d.isInContractTrade) {
            (uint tradeType, int actualIn) = LibExchange.updateOrderBalanceDebit(d.order, uint112(d.filledBase),
                uint112(d.filledQuote),
                d.order.buySide == 0 ? LibExchange.kSell : LibExchange.kBuy, assetBalances, liabilities);
            LibExchange.creditUserAssets(tradeType, d.order.senderAddress, actualIn, d.path[d.path.length-1], assetBalances, liabilities);

        } else {
            _payMatcherFee(d.order, assetBalances, liabilities);
            if (d.isRetainFee) {
                LibExchange.creditUserAssets(1, d.order.senderAddress, int(amountIn), d.path[d.path.length-1], assetBalances, liabilities);
            }
        }
    }

    function doFillThroughOrionPool(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        mapping(bytes32 => uint192) storage filledAmounts
    ) public {
        calcAmounts(d, assetBalances);

        LibValidator.checkOrderSingleMatch(d.order, msg.sender, d.allowedMatcher, uint112(d.filledAmount), block.timestamp,
            d.asset_spend, d.path[d.path.length - 1]);

        try IPoolFunctionality(d.orionpoolRouter).doSwapThroughOrionPool(
            d.isInContractTrade ? address(this) : d.order.senderAddress,
            uint112(d.amount_spend),
            uint112(d.amount_receive),
            d.path,
            d.order.buySide == 0,
            d.to
        ) returns(uint amountOut, uint amountIn) {
            calcAmountInOutAfterSwap(d, amountOut, amountIn, assetBalances, liabilities);
        } catch(bytes memory) {
            d.filledBase = 0;
            d.filledPrice = d.order.price;
            _payMatcherFee(d.order, assetBalances, liabilities);
        }

        updateFilledAmount(d.order, uint112(d.filledBase), filledAmounts);

        emit LibExchange.NewTrade(
            d.order.senderAddress,
            address(1),
            d.order.baseAsset,
            d.order.quoteAsset,
            uint64(d.filledPrice),
            uint192(d.filledBase),
            uint192(d.filledQuote)
        );
    }

    function _payMatcherFee(
        LibValidator.Order memory order,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        LibExchange._updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int(order.matcherFee), assetBalances, liabilities);
        LibExchange._updateBalance(order.matcherAddress, order.matcherFeeAsset, int(order.matcherFee), assetBalances, liabilities);
    }


    function doWithdrawToPool(
        address assetA,
        address asseBNotETH,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        address _orionpoolRouter
    ) public returns(uint amountA, uint amountB) {
        require(asseBNotETH != address(0), "TokenBIsETH");

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
        }

        LibExchange._updateBalance(msg.sender, assetA, -1*int256(amountADesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][assetA] >= 0, "E1w1A");

        LibExchange._updateBalance(msg.sender, asseBNotETH, -1*int256(amountBDesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][asseBNotETH] >= 0, "E1w1B");

        (amountA, amountB, ) = IPoolFunctionality(_orionpoolRouter).addLiquidityFromExchange(
            assetA,
            asseBNotETH,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            msg.sender
        );

        // Refund
        if (amountADesired > amountA) {
            LibExchange._updateBalance(msg.sender, assetA, int(amountADesired - amountA), assetBalances, liabilities);
        }

        if (amountBDesired > amountB) {
            LibExchange._updateBalance(msg.sender, asseBNotETH, int(amountBDesired - amountB), assetBalances, liabilities);
        }
    }

}

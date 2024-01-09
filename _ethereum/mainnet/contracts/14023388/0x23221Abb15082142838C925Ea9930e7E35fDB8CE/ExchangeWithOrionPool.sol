// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./Exchange.sol";
import "./IPoolSwapCallback.sol";
import "./IPoolFunctionality.sol";
import "./LibPool.sol";
import "./IOrionPoolV2Router02Ext.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ExchangeWithOrionPool is Exchange, IPoolSwapCallback {

    using SafeERC20 for IERC20;

    address public _orionpoolRouter;
    mapping (address => bool) orionpoolAllowances;

    address public WETH;

    modifier initialized {
        require(address(_orionToken)!=address(0), "E16I");
        require(_oracleAddress!=address(0), "E16I");
        require(_allowedMatcher!=address(0), "E16I");
        require(_orionpoolRouter!=address(0), "E16I");
        _;
    }

    /**
     * @dev set basic Exchange params
     * @param orionToken - base token address
     * @param priceOracleAddress - adress of PriceOracle contract
     * @param allowedMatcher - address which has authorization to match orders
     * @param orionpoolRouter - OrionPool Functionality contract address for changes through orionpool
     */
    function setBasicParams(
        address orionToken,
        address priceOracleAddress,
        address allowedMatcher,
        address orionpoolRouter
    ) public onlyOwner {
        _orionToken = IERC20(orionToken);
        _oracleAddress = priceOracleAddress;
        _allowedMatcher = allowedMatcher;
        _orionpoolRouter = orionpoolRouter;
        WETH = IPoolFunctionality(_orionpoolRouter).getWETH();
    }

    //Important catch-all a function that should only accept ethereum and don't allow do something with it
    //We accept ETH there only from out router or wrapped ethereum contract.
    //If router sends some ETH to us - it's just swap completed, and we don't need to do something
    receive() external payable {
        require(msg.sender == _orionpoolRouter || msg.sender == WETH, "NPF");
    }

    function safeAutoTransferFrom(address token, address from, address to, uint value) override external {
        require(msg.sender == _orionpoolRouter, "Only _orionpoolRouter allowed");
        SafeTransferHelper.safeAutoTransferFrom(WETH, token, from, to, value);
    }

    /**
     * @notice (partially) settle buy order with OrionPool as counterparty
     * @dev order and orionpool path are submitted, it is necessary to match them:
        check conditions in order for compliance filledPrice and filledAmount
        change tokens via OrionPool
        check that final price after exchange not worse than specified in order
        change balances on the contract respectively
     * @param order structure of buy side orderbuyOrderHash
     * @param filledAmount amount of purchaseable token
     * @param path array of assets addresses (each consequent asset pair is change pair)
     */

    function fillThroughOrionPool(
        LibValidator.Order memory order,
        uint112 filledAmount,
        uint64 blockchainFee,
        address[] calldata path
    ) public nonReentrant {

        LibPool.OrderExecutionData memory tmp = LibPool.doFillThroughOrionPool(
            order,
            filledAmount,
            blockchainFee,
            path,
            _allowedMatcher,
            assetBalances,
            liabilities,
            _orionpoolRouter,
            filledAmounts
        );

        require(checkPosition(order.senderAddress), tmp.isInContractTrade ? (order.buySide == 0 ? "E1PS" : "E1PB") : "E1PF");

        emit NewTrade(
            order.senderAddress,
            address(1),
            order.baseAsset,
            order.quoteAsset,
            uint64(tmp.filledPrice),
            uint192(tmp.filledBase),
            uint192(tmp.filledQuote)
        );

    }

    function swapThroughOrionPool(
        uint112     amount_spend,
        uint112     amount_receive,
        address[] calldata   path,
        bool        is_exact_spend
    ) public payable nonReentrant {
        bool isCheckPosition = LibPool.doSwapThroughOrionPool(amount_spend, amount_receive, path, is_exact_spend,
            assetBalances, liabilities, _orionpoolRouter);
        if (isCheckPosition) {
            require(checkPosition(msg.sender), "E1PS");
        }
    }
}


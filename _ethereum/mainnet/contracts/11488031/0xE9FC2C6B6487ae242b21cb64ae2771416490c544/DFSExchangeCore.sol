pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./DSMath.sol";
import "./TokenInterface.sol";
import "./ExchangeInterfaceV3.sol";
import "./ZrxAllowlist.sol";
import "./DFSExchangeData.sol";
import "./DFSExchangeHelper.sol";
import "./SaverExchangeRegistry.sol";
import "./OffchainWrapperInterface.sol";

contract DFSExchangeCore is DFSExchangeHelper, DSMath, DFSExchangeData {

    string public constant ERR_SLIPPAGE_HIT = "Slippage hit";
    string public constant ERR_DEST_AMOUNT_MISSING = "Dest amount missing";
    string public constant ERR_WRAPPER_INVALID = "Wrapper invalid";
    string public constant ERR_NOT_ZEROX_EXCHANGE = "Zerox exchange invalid";

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(EXCHANGE_WETH_ADDRESS).deposit{value: exData.srcAmount}();
        }

        exData.srcAmount -= getFee(exData.srcAmount, exData.user, exData.srcAddr, exData.dfsFeeDivider);

        // Try 0x first and then fallback on specific wrapper
        if (exData.offchainData.price > 0) {
            (success, swapedTokens) = takeOrder(exData, ActionType.SELL);

            if (success) {
                wrapper = exData.offchainData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        if (exData.destAddr == EXCHANGE_WETH_ADDRESS) {
            require(getBalance(KYBER_ETH_ADDRESS) >= wmul(exData.minPrice, exData.srcAmount), ERR_SLIPPAGE_HIT);
        } else {
            require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), ERR_SLIPPAGE_HIT);
        }

        // if anything is left in weth, pull it to user as eth
        if (getBalance(EXCHANGE_WETH_ADDRESS) > 0) {
            TokenInterface(EXCHANGE_WETH_ADDRESS).withdraw(
                TokenInterface(EXCHANGE_WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, swapedTokens);
    }

    /// @notice Internal method that preforms a buy on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and srcAmount
    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, ERR_DEST_AMOUNT_MISSING);

        exData.srcAmount -= getFee(exData.srcAmount, exData.user, exData.srcAddr, exData.dfsFeeDivider);

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(EXCHANGE_WETH_ADDRESS).deposit{value: exData.srcAmount}();
        }

        if (exData.offchainData.price > 0) {
            (success, swapedTokens) = takeOrder(exData, ActionType.BUY);

            if (success) {
                wrapper = exData.offchainData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        if (exData.destAddr == EXCHANGE_WETH_ADDRESS) {
            require(getBalance(KYBER_ETH_ADDRESS) >= exData.destAmount, ERR_SLIPPAGE_HIT);
        } else {
            require(getBalance(exData.destAddr) >= exData.destAmount, ERR_SLIPPAGE_HIT);
        }

        // if anything is left in weth, pull it to user as eth
        if (getBalance(EXCHANGE_WETH_ADDRESS) > 0) {
            TokenInterface(EXCHANGE_WETH_ADDRESS).withdraw(
                TokenInterface(EXCHANGE_WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) private returns (bool success, uint256) {
        if (!ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.offchainData.exchangeAddr)) {
            return (false, 0);
        }

        if (SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.offchainData.wrapper)) {
            return (false, 0);
        }

        // send src amount
        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        return OffchainWrapperInterface(_exData.offchainData.wrapper).takeOrder{value: _exData.offchainData.protocolFee}(_exData, _type);
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param _exData Exchange data struct
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), ERR_WRAPPER_INVALID);

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV3(_exData.wrapper).
                    sell(_exData.srcAddr, _exData.destAddr, _exData.srcAmount, _exData.wrapperData);
        } else {
            swapedTokens = ExchangeInterfaceV3(_exData.wrapper).
                    buy(_exData.srcAddr, _exData.destAddr, _exData.destAmount, _exData.wrapperData);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

pragma solidity ^0.6.0;

import "./DSMath.sol";
import "./TokenInterface.sol";
import "./ExchangeInterfaceV2.sol";
import "./ZrxAllowlist.sol";
import "./SaverExchangeHelper.sol";
import "./SaverExchangeRegistry.sol";

contract SaverExchangeCore is SaverExchangeHelper, DSMath {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint srcAmount;
        uint destAmount;
        uint minPrice;
        address wrapper;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.srcAmount;

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        // Try 0x first and then fallback on specific wrapper
        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            (success, swapedTokens, tokensLeft) = takeOrder(exData, address(this).balance, ActionType.SELL);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
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

        require(exData.destAmount != 0, "Dest amount must be specified");

        // if selling eth, convert to weth
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        if (exData.price0x > 0) { 
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            (success, swapedTokens,) = takeOrder(exData, address(this).balance, ActionType.BUY);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }

        // fallback to desired wrapper if 0x failed
        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= exData.destAmount, "Final amount isn't correct");

        // if anything is left in weth, pull it to user as eth
        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _ethAmount Ether fee needed for 0x order
    function takeOrder(
        ExchangeData memory _exData,
        uint256 _ethAmount,
        ActionType _type
    ) private returns (bool success, uint256, uint256) {

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.callData, 36, _exData.destAmount);
        }

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.exchangeAddr)) {
            (success, ) = _exData.exchangeAddr.call{value: _ethAmount}(_exData.callData);
        } else {
            success = false;
        }

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.srcAmount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_exData.srcAddr);

            // convert weth -> eth if needed
            if (_exData.destAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr);
        }

        return (success, tokensSwaped, tokensLeft);
    }

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @param _exchangeType Which exchange will be used
    /// @param _type Type of action SELL|BUY
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        ExchangeType _exchangeType,
        ActionType _type
    ) public returns (address, uint256) {

        if (_exchangeType == ExchangeType.OASIS) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        if (_exchangeType == ExchangeType.KYBER) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        if (_exchangeType == ExchangeType.UNISWAP) {
            return (UNISWAP_WRAPPER, getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        uint expectedRateKyber = getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount, _type);
        uint expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount, _type);
        uint expectedRateOasis = getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount, _type);

        if (_type == ActionType.SELL) {
            return getBiggestRate(expectedRateKyber, expectedRateUniswap, expectedRateOasis);
        } else {
            return getSmallestRate(expectedRateKyber, expectedRateUniswap, expectedRateOasis);
        }
    }

    /// @notice Return the expected rate from the exchange wrapper
    /// @dev In case of Oasis/Uniswap handles the different precision tokens
    /// @param _wrapper Address of exchange wrapper
    /// @param _srcToken From token
    /// @param _destToken To token
    /// @param _amount Amount to be exchanged
    /// @param _type Type of action SELL|BUY
    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount,
        ActionType _type
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        if (_type == ActionType.SELL) {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getSellRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));

        } else {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getBuyRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));
        }

        if (success) {
            uint rate = sliceUint(result, 0);

            if (_wrapper != KYBER_WRAPPER) {
                rate = rate * (10**(18 - getDecimals(_destToken)));
            }

            return rate;
        }

        return 0;
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param _exData Exchange data struct
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), "Wrapper is not valid");

        uint ethValue = 0;

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);
        
        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    sell{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.srcAmount);
        } else {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    buy{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.destAmount);
        }
    }

    /// @notice Finds the biggest rate between exchanges, needed for sell rate
    /// @param _expectedRateKyber Kyber rate
    /// @param _expectedRateUniswap Uniswap rate
    /// @param _expectedRateOasis Oasis rate
    function getBiggestRate(
        uint _expectedRateKyber,
        uint _expectedRateUniswap,
        uint _expectedRateOasis
    ) internal pure returns (address, uint) {
        if (
            (_expectedRateUniswap >= _expectedRateKyber) && (_expectedRateUniswap >= _expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, _expectedRateUniswap);
        }

        if (
            (_expectedRateKyber >= _expectedRateUniswap) && (_expectedRateKyber >= _expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, _expectedRateKyber);
        }

        if (
            (_expectedRateOasis >= _expectedRateKyber) && (_expectedRateOasis >= _expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, _expectedRateOasis);
        }
    }

    /// @notice Finds the smallest rate between exchanges, needed for buy rate
    /// @param _expectedRateKyber Kyber rate
    /// @param _expectedRateUniswap Uniswap rate
    /// @param _expectedRateOasis Oasis rate
    function getSmallestRate(
        uint _expectedRateKyber,
        uint _expectedRateUniswap,
        uint _expectedRateOasis
    ) internal pure returns (address, uint) {
        if (
            (_expectedRateUniswap <= _expectedRateKyber) && (_expectedRateUniswap <= _expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, _expectedRateUniswap);
        }

        if (
            (_expectedRateKyber <= _expectedRateUniswap) && (_expectedRateKyber <= _expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, _expectedRateKyber);
        }

        if (
            (_expectedRateOasis <= _expectedRateKyber) && (_expectedRateOasis <= _expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, _expectedRateOasis);
        }
    }

    function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert("Incorrent lengt while writting bytes32");
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

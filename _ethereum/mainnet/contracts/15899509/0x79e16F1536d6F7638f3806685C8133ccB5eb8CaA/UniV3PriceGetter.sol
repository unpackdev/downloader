// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IApePair.sol";
import "./ERC20.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./TickMath.sol";
import "./FixedPoint96.sol";
import "./FullMath.sol";

// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDT, USDC, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// UNIV3 ETH ApeSwap only version

contract UniV3PriceGetter {
    address public constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; //UNIV3 Factory

    //All returned prices calculated with this precision (18 decimals)
    uint256 private constant PRECISION = 10**DECIMALS; //1e18 == $1
    uint256 public constant DECIMALS = 18;

    //Token addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    //Token value constants
    uint256 private constant USDC_RAW_PRICE = 1e18;

    //returns the price of any token in USD based on common pairings; zero on failure
    function getPrice(address token, uint32 _secondsAgo) public view returns (uint256) {
        uint256 ETHPrice = getETHPrice(_secondsAgo);
        uint256 pegPrice = pegTokenPrice(token, ETHPrice);
        if (pegPrice != 0) return pegPrice;

        return _getPrice(token, ETHPrice, _secondsAgo);
    }

    //returns the price of an LP token. token0/token1 price; zero on failure
    function getLPPrice(
        address token0,
        address token1,
        uint24 fee,
        uint32 _secondsAgo
    ) public view returns (uint256) {
        return pairTokensAndValue(token0, token1, fee, _secondsAgo);
    }

    //returns the prices of multiple tokens, zero on failure
    function getPrices(address[] memory tokens, uint32 _secondsAgo) public view returns (uint256[] memory prices) {
        prices = new uint256[](tokens.length);
        uint256 ethPrice = getETHPrice(_secondsAgo);

        for (uint256 i; i < prices.length; i++) {
            address token = tokens[i];
            uint256 pegPrice = pegTokenPrice(token, ethPrice);

            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = _getPrice(token, ethPrice, _secondsAgo);
        }
    }

    //returns the current USD price of ETH based on primary stablecoin pairs
    function getETHPrice(uint32 _secondsAgo) public view returns (uint256 ethPrice) {
        uint256 price;
        uint256 totalPrice;
        uint256 totalBalance;

        uint24[] memory fees = new uint24[](3);
        fees[0] = 500;
        fees[1] = 3000;
        fees[2] = 10000;
        for (uint24 feeIndex = 0; feeIndex < 3; feeIndex++) {
            uint24 fee = fees[feeIndex];
            price = pairTokensAndValue(WETH, DAI, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(WETH, DAI, fee);
                uint256 balance = IERC20(WETH).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }

            price = pairTokensAndValue(WETH, USDC, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(WETH, USDC, fee);
                uint256 balance = IERC20(WETH).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }

            price = pairTokensAndValue(WETH, USDT, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(WETH, USDT, fee);
                uint256 balance = IERC20(WETH).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }
        }

        if (totalBalance == 0) {
            return 0;
        }
        ethPrice = totalPrice / totalBalance;
    }

    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price
    function _getPrice(
        address token,
        uint256 ethPrice,
        uint32 _secondsAgo
    ) internal view returns (uint256 rawPrice) {
        uint256 pegPrice = pegTokenPrice(token, ethPrice);

        if (pegPrice != 0) return pegPrice;

        uint256 price;
        uint256 totalPrice;
        uint256 totalBalance;

        uint24[] memory fees = new uint24[](3);
        fees[0] = 500;
        fees[1] = 3000;
        fees[2] = 10000;
        for (uint24 feeIndex = 0; feeIndex < 3; feeIndex++) {
            uint24 fee = fees[feeIndex];
            price = pairTokensAndValue(token, WETH, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(token, WETH, fee);
                uint256 balance = IERC20(token).balanceOf(pair);
                totalPrice += price * (ethPrice / 10**18) * balance;
                totalBalance += balance;
            }

            price = pairTokensAndValue(token, DAI, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(token, DAI, fee);
                uint256 balance = IERC20(token).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }

            price = pairTokensAndValue(token, USDC, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(token, USDC, fee);
                uint256 balance = IERC20(token).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }

            price = pairTokensAndValue(token, USDT, fee, _secondsAgo);
            if (price > 0) {
                address pair = pairFor(token, USDT, fee);
                uint256 balance = IERC20(token).balanceOf(pair);
                totalPrice += price * balance;
                totalBalance += balance;
            }
        }

        if (totalBalance == 0) {
            return 0;
        }
        rawPrice = totalPrice / totalBalance;
    }

    //if one of the peg tokens, returns that price, otherwise zero
    function pegTokenPrice(address token, uint256 ethPrice) private pure returns (uint256) {
        if (token == USDT || token == USDC || token == DAI) return PRECISION;

        if (token == WETH) return ethPrice;

        return 0;
    }

    function pegTokenPrice(address token, uint32 _secondsAgo) private view returns (uint256) {
        if (token == USDT || token == USDC || token == DAI) return PRECISION;

        if (token == WETH) return getETHPrice(_secondsAgo);

        return 0;
    }

    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token
    function pairTokensAndValue(
        address token0,
        address token1,
        uint24 fee,
        uint32 _secondsAgo
    ) internal view returns (uint256 price) {
        address tokenPegPair = pairFor(token0, token1, fee);

        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;

        assembly {
            size := extcodesize(tokenPegPair)
        }

        if (size == 0) return 0;

        uint256 sqrtPriceX96;

        if (_secondsAgo == 0) {
            // return the current price if _secondsAgo == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(tokenPegPair).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = _secondsAgo; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(tokenPegPair).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / _secondsAgo));
        }

        uint256 token0Decimals;
        try ERC20(token0).decimals() returns (uint8 dec) {
            token0Decimals = dec;
        } catch {
            token0Decimals = 18;
        }

        uint256 token1Decimals;
        try ERC20(token1).decimals() returns (uint8 dec) {
            token1Decimals = dec;
        } catch {
            token1Decimals = 18;
        }

        if (token1 < token0) {
            price = (2**192) / ((sqrtPriceX96)**2 / uint256(10**(token0Decimals + 18 - token1Decimals)));
        } else {
            price = ((sqrtPriceX96)**2) / ((2**192) / uint256(10**(token0Decimals + 18 - token1Decimals)));
        }
    }

    function pairFor(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address pair) {
        pair = IUniswapV3Factory(FACTORY).getPool(tokenA, tokenB, fee);
    }
}

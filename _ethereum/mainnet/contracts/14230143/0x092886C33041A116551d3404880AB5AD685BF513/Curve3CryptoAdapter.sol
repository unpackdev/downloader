// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IExchangeAdapter.sol";
import "./IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurve3Crypto {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external;

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;
}

contract Curve3CryptoAdapter is IExchangeAdapter {
    IERC20 public constant lpToken =
        IERC20(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);

    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 1; // usdt
        if (coin == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return 2; // wbtc
        if (coin == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 3; // weth
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurve3Crypto curve = ICurve3Crypto(pool);
        uint256 i = indexByCoin(fromToken);
        uint256 j = indexByCoin(toToken);
        require(i != 0 && j != 0, "3cryptoAdapter: can't swap");

        curve.exchange(i - 1, j - 1, amount, 0, false);

        return IERC20(toToken).balanceOf(address(this));
    }

    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurve3Crypto curve = ICurve3Crypto(pool);
        uint256[3] memory amounts;
        uint256 i = indexByCoin(fromToken);
        require(i != 0, "3cryptoAdapter: can't enter");

        amounts[i - 1] = amount;

        curve.add_liquidity(amounts, 0);

        return lpToken.balanceOf(address(this));
    }

    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurve3Crypto curve = ICurve3Crypto(pool);

        uint256 i = indexByCoin(toToken);
        require(i != 0, "3cryptoAdapter: can't exit");

        curve.remove_liquidity_one_coin(amount, i - 1, 0);

        return IERC20(toToken).balanceOf(address(this));
    }
}

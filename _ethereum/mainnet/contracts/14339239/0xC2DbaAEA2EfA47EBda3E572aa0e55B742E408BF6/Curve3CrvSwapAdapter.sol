// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";

import "./IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurve3Crv {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

contract Curve3CrvSwapAdapter is IExchangeAdapter {
    IERC20 public constant token3crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 1; // dai
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 2; // usdc
        if (coin == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 3; // usdt
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurve3Crv pool3crv = ICurve3Crv(pool);

        if (toToken == address(token3crv)) {
            // enter 3crv pool to get 3crv token
            int128 i = indexByCoin(fromToken);
            require(i != 0, "Curve3CrvSwapAdapter: can't swap");
            uint256[3] memory amounts;
            amounts[uint256(int256(i - 1))] = amount;

            pool3crv.add_liquidity(amounts, 0);

            return token3crv.balanceOf(address(this));
        } else if (fromToken == address(token3crv)) {
            // exit 3crv pool to get stable
            int128 i = indexByCoin(toToken);
            require(i != 0, "Curve3CrvSwapAdapter: can't swap");

            pool3crv.remove_liquidity_one_coin(amount, i - 1, 0);

            return IERC20(toToken).balanceOf(address(this));
        } else {
            revert("Curve3CrvSwapAdapter: can't swap");
        }
    }

    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("Curve3CrvSwapAdapter: cant enter");
    }

    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("Curve3CrvSwapAdapter: can't exit");
    }
}

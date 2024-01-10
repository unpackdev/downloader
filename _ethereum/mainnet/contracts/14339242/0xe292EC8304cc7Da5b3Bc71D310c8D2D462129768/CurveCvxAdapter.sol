// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IExchangeAdapter.sol";
import "./IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveCvx {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external returns (uint256);
}

contract CurveCvxAdapter {
    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1; // weth
        if (coin == 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B) return 2; // cvx
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveCvx curve = ICurveCvx(pool);
        uint256 i = indexByCoin(fromToken);
        uint256 j = indexByCoin(toToken);
        require(i != 0 && j != 0, "cvxAdapter: can't swap");

        return curve.exchange(i - 1, j - 1, amount, 0, false);
    }

    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveCvx curve = ICurveCvx(pool);
        uint256[2] memory amounts;
        uint256 i = indexByCoin(fromToken);
        require(i != 0, "cvxAdapter: can't enter");

        amounts[i - 1] = amount;

        return curve.add_liquidity(amounts, 0);
    }

    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveCvx curve = ICurveCvx(pool);

        uint256 i = indexByCoin(toToken);
        require(i != 0, "crvAdapter: can't exit");

        return curve.remove_liquidity_one_coin(amount, i - 1, 0);
    }
}

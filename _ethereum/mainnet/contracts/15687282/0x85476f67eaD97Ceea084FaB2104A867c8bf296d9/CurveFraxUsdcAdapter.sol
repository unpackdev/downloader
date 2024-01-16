// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./IExchangeAdapter.sol";


// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveFrax {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurveFraxUsdcAdapter is IExchangeAdapter {
    address public constant fraxUsdcLp = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    ICurveFrax public constant fraxPool =
        ICurveFrax(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);


    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0x853d955aCEf822Db058eb8505911ED77F175b99e) return 1; // frax
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 2; // usdc
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveFrax curve = ICurveFrax(pool);
        if (toToken == fraxUsdcLp) {
            uint128 i = uint128(indexByCoin(fromToken));
            require(i != 0, "CurveFraxUsdcAdapter: Can't Swap");
            uint256[2] memory entryVector;
            entryVector[i - 1] = amount;
            return curve.add_liquidity(entryVector, 0);
        } else if (fromToken == fraxUsdcLp) {
            int128 i = indexByCoin(toToken);
            require(i != 0, "CurveFraxUsdcAdapter: Can't Swap");
            return curve.remove_liquidity_one_coin(amount, i-1, 0);
        } else {
            revert("CurveFraxUsdcAdapter: Can't Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveFraxUsdcAdapter: Can't Swap");


    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveFraxUsdcAdapter: Can't Swap");
    }
}
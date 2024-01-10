// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IExchangeAdapter.sol";
import "./IERC20Metadata.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveUst {
    function exchange_underlying(
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

interface ICurve3Crv {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

contract CurveUstAdapter {
    address public constant fraxLp = 0x94e131324b6054c0D789b190b2dAC504e4361b53;
    ICurve3Crv public constant pool3Crv =
        ICurve3Crv(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    function indexByUnderlyingCoin(address coin) public pure returns (int128) {
        if (coin == 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD) return 1; // ust
        if (coin == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 2; // dai
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 3; // usdc
        if (coin == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 4; // usdt
        return 0;
    }

    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD) return 1; // ust
        if (coin == 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490) return 2; // 3Crv
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);
        int128 i = indexByUnderlyingCoin(fromToken);
        int128 j = indexByUnderlyingCoin(toToken);
        require(i != 0 && j != 0, "CurveUstAdapter: can't swap");

        return curve.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);

        uint128 i = uint128(indexByCoin(fromToken));

        if (i != 0) {
            uint256[2] memory entryVector_;
            entryVector_[i - 1] = amount;
            return curve.add_liquidity(entryVector_, 0);
        }

        i = uint128(indexByUnderlyingCoin(fromToken));
        IERC20 threeCrvToken = IERC20(
            0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
        );

        require(i != 0, "CrvUstAdapter: can't enter");
        uint256[3] memory entryVector;
        entryVector[i - 2] = amount;

        pool3Crv.add_liquidity(entryVector, 0);
        return
            curve.add_liquidity([0, threeCrvToken.balanceOf(address(this))], 0);
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);

        int128 i = indexByCoin(toToken);

        if (i != 0) {
            return curve.remove_liquidity_one_coin(amount, i - 1, 0);
        }

        i = indexByUnderlyingCoin(toToken);
        require(i != 0, "CrvUstAdapter: can't exit");
        uint256 amount3Crv = curve.remove_liquidity_one_coin(amount, 1, 0);
        pool3Crv.remove_liquidity_one_coin(amount3Crv, i - 2, 0);

        return IERC20(toToken).balanceOf(address(this));
    }
}

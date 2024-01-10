//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./P.sol";

interface I3Curve {
    function get_virtual_price() external view returns (uint256);
}

interface IMeta3Curve {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    function get_price_cumulative_last() external view returns (uint256[2] memory);
    function block_timestamp_last() external view returns (uint256);
    // function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
}

contract CurvePrice {

    using SafeMath for uint256;

    uint256 private constant A_PRECISION = 100;
    address private constant POOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;
    address private constant CRV3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 private constant N_COINS  = 2;
    uint256 private constant RATE_MULTIPLIER = 10 ** 30;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant i = 0;
    uint256 private constant j = 1;
    address[2] private tokens = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490];

    function getCurve() public view returns (P.Pool memory pool) {
        pool.pool = POOL;
        pool.tokens = tokens;
        uint256[2] memory balances = IMeta3Curve(POOL).get_balances();
        pool.balances = balances;
        uint256[2] memory rates = getRates();
        uint256[2] memory xp = getXP(balances, rates);
        uint256 a = IMeta3Curve(POOL).A_precise();
        uint256 D = getD(xp, a);

        pool.price = getCurvePrice(xp, rates, a, D);
        rates[0] = rates[0].mul(pool.price).div(1e6);
        pool.liquidity = getCurveUSDValue(balances, rates);
        pool.deltaB = getCurveDeltaB(balances[0], D);
    }

    function getCurveDeltaB(uint256 balance, uint256 D) private pure returns (int deltaB) {
        uint256 pegBeans = D / 2 / 1e12;
        deltaB = int256(pegBeans) - int256(balance);
    }
    
    function getCurvePrice(uint256[2] memory xp, uint256[2] memory rates, uint256 a, uint256 D) private pure returns (uint) {
        uint256 x = xp[i] + (1 * rates[i] / PRECISION);
        uint256 y = getY(x, xp, a, D);
        uint256 dy = xp[j] - y - 1;
        return dy / 1e6;
    }

    function getCurveUSDValue(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint) {
        uint256[2] memory value = getXP(balances, rates);
        return (value[0] + value[1]) / 1e12;
    }

    function getY(uint256 x, uint256[2] memory xp, uint256 a, uint256 D) private pure returns (uint256 y) {

        uint256 S_ = 0;
        uint256 _x = 0;
        uint256 y_prev = 0;
        uint256 c = D;
        uint256 Ann = a * N_COINS;

        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i == i) _x = x;
            else if (_i != j) _x = xp[_i];
            else continue;
            S_ += _x;
            c = c * D / (_x * N_COINS);
        }

        c = c * D * A_PRECISION / (Ann * N_COINS);
        uint256 b = S_ + D * A_PRECISION / Ann; // - D
        y = D;

        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y*y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev && y - y_prev <= 1) return y;
            else if (y_prev - y <= 1) return y;
        }
        require(false, "Price: Convergence false");
    }



    function getD(uint256[2] memory xp, uint256 a) private pure returns (uint D) {
        
        /*  
        * D invariant calculation in non-overflowing integer operations
        * iteratively
        *
        * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
        *
        * Converging solution:
        * D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
        */
        uint256 S;
        uint256 Dprev;
        for (uint _i = 0; _i < xp.length; _i++) {
            S += xp[_i];
        }
        if (S == 0) return 0;

        D = S;
        uint256 Ann = a * N_COINS;
        for (uint _i = 0; _i < 256; _i++) {
            uint256 D_P = D;
            for (uint _j = 0; _j < xp.length; _j++) {
                D_P = D_P * D / (xp[_j] * N_COINS);  // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D = (Ann * S / A_PRECISION + D_P * N_COINS) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev && D - Dprev <= 1) return D;
            else if (Dprev - D <= 1) return D;
        }
        // convergence typically occurs in 4 rounds or less, this should be unreachable!
        // if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
        require(false, "Price: Convergence false");
    }

    function getXP(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint256[2] memory xp) {
        xp[0] = balances[0].mul(rates[0]).div(PRECISION);
        xp[1] = balances[1].mul(rates[1]).div(PRECISION);
    }

    function getRates() private view returns (uint256[2] memory rates) {
        return [RATE_MULTIPLIER, I3Curve(CRV3_POOL).get_virtual_price()];
    }
}

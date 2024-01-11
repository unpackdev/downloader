//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./P.sol";
import "./LibMetaCurve.sol";
import "./LibHelpers.sol";

interface IPlainPool {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    // function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
}

contract BeanLUSDPrice {

    using SafeMath for uint256;

    //-------------------------------------------------------------------------------------------------------------------
    // Mainnet
    address private constant POOL = 0xD652c40fBb3f06d6B58Cb9aa9CFF063eE63d465D;
    address private constant BEAN_3CRV_POOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;
    address private constant LUSD_3CRV_POOL = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address private constant CRV3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    //-------------------------------------------------------------------------------------------------------------------
    // Ropsten
    // address private constant POOL = TODO: Deploy BEAN_LUSD_POOL
    // address private constant BEAN_3CRV_POOL = 0x9ED0380C5dedadd3b2a32f5D5FD6B3929f8d39d9;
    // address private constant LUSD_3CRV_POOL = TODO: Deploy LUSD_CRV_POOL
    // address private constant CRV3_POOL = 0x6412bbCeEf0b384B7f8142BDafeFE119178F1E22;
    //-------------------------------------------------------------------------------------------------------------------

    uint256 private constant A_PRECISION = 100; 
    uint256 private constant N_COINS  = 2;
    uint256 private constant RATE_MULTIPLIER = 10 ** 30;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LUSD_RM = 1e24;
    uint256 private constant i = 0;
    uint256 private constant j = 1;
    uint256[2] private decimals = [6, 18];
    address[2] private tokens = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0];

    function getBeanLUSDCurve() public view returns (P.Pool memory pool) {
        pool.pool = POOL;
        pool.tokens = tokens;

        uint256 bean3CrvPrice = LibMetaCurve.price(BEAN_3CRV_POOL, decimals[0]);
        uint256 lusd3CrvPrice = LibMetaCurve.price(LUSD_3CRV_POOL, decimals[1]);

        uint256[2] memory balances = IPlainPool(POOL).get_balances();
        pool.balances = balances;
        uint256[2] memory rates = getPlainRates();
        uint256[2] memory xp = LibCurve.getXP(balances, rates);
        uint256 a = IPlainPool(POOL).A_precise();
        uint256 D = LibCurve.getD(xp, a);
        uint256 poolPrice = LibCurve.getCurvePrice(xp, rates, a, D);
        pool.price = poolPrice.mul(lusd3CrvPrice).div(1e18);
        pool.liquidity = getBeanLUSDCurveUSDValue(balances, [bean3CrvPrice*1e12, lusd3CrvPrice]);
        uint256 targetPrice = LUSD_RM.div(lusd3CrvPrice);
        pool.deltaB = getPlainPoolDeltaB(xp, D, a, targetPrice, poolPrice);
    }

    struct DeltaB {
        uint256 pegBeans;
        int256 currentBeans;
        int256 deltaBToPeg;
        int256 deltaPriceToTarget;
        int256 deltaPriceToPeg;
        int256 estDeltaB;
        uint256 kBeansAtPeg; 
    }

    function getPlainPoolDeltaB(uint256[2] memory xp, uint256 D, uint256 a, uint256 targetPrice, uint256 poolPrice) private pure returns (int deltaB) {
        DeltaB memory db;
        db.currentBeans = int256(xp[0]);
        db.pegBeans = D / 2;
        db.deltaBToPeg = int256(db.pegBeans) - db.currentBeans;
        db.kBeansAtPeg = LibHelpers.sqrt(db.pegBeans * db.pegBeans * 1e6 / targetPrice);

        uint256 prevPrice;
        uint256 x;
        uint256 x2;

        for (uint256 k = 0; k < 256; k++) {

            db.deltaPriceToTarget = int256(targetPrice) - int256(poolPrice);
            db.deltaPriceToPeg = 1e6 - int256(poolPrice);
            db.deltaBToPeg = int256(db.pegBeans) - int256(xp[0]);
            db.estDeltaB = (db.deltaBToPeg * int256(db.deltaPriceToTarget * 1e18 / db.deltaPriceToPeg)) / 1e18;
            x = uint256(int256(xp[0]) + db.estDeltaB);
            x2 = LibCurve.getY(x, xp, a, D);
            xp[0] = x;
            xp[1] = x2;
            prevPrice = poolPrice;
            poolPrice = LibCurve.getCurvePrice(xp, [RATE_MULTIPLIER, RATE_MULTIPLIER], a, D);
            if (prevPrice > poolPrice) {
                if (prevPrice - poolPrice <= 1) break;
            }
            else if (poolPrice - prevPrice <= 1) break;
        }
        deltaB = (int256(xp[0]) - db.currentBeans) / 1e12;
    }

    function getBeanLUSDCurveUSDValue(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint) {
        uint256[2] memory value = LibCurve.getXP(balances, rates);
        return value[0] + (value[1] / 1e12);
    }

    function getPlainRates() private view returns (uint256[2] memory rates) {
        return [10 ** (36-decimals[0]), 10 ** (36-decimals[1])];
    }
}

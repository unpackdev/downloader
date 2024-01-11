//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./CurvePrice.sol";
import "./UniswapPrice.sol";
import "./BeanLUSDPrice.sol";

contract BeanstalkPrice is UniswapPrice, CurvePrice, BeanLUSDPrice {

    using SafeMath for uint256;

    struct Prices {
        uint256 price;
        uint256 liquidity;
        int deltaB;
        P.Pool[] ps;
    }

    function price() external view returns (Prices memory p) {
        p.ps = new P.Pool[](3);
        p.ps[0] = getCurve();
        p.ps[1] = getUniswap();
        p.ps[2] = getBeanLUSDCurve();


        for (uint256 i = 0; i < p.ps.length; i++) {
            p.price += p.ps[i].price * p.ps[i].liquidity;
            p.liquidity += p.ps[i].liquidity;
            p.deltaB += p.ps[i].deltaB;
        }
        p.price /= p.liquidity;
    }
}
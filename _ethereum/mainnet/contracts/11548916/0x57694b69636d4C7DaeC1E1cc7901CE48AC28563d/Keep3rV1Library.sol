// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
import "./IUniswapV2PairLight.sol";

library Keep3rV1Library{
    function getReserve(address pair, address reserve) external view returns (uint) {
        (uint _r0, uint _r1,) = IUniswapV2PairLight(pair).getReserves();
        if (IUniswapV2PairLight(pair).token0() == reserve) {
            return _r0;
        } else if (IUniswapV2PairLight(pair).token1() == reserve) {
            return _r1;
        } else {
            return 0;
        }
    }
}

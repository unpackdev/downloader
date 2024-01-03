pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function getReserves() external view returns(uint112, uint112, uint32);
}

contract Reserves {
    constructor () public {

    }

    function getAllReserves(address[] memory pairs) public view returns (uint112[2][] memory) {
        uint112[2][] memory output = new uint112[2][](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            (uint112 reservesA, uint112 reservesB,) = pair.getReserves();
            uint112[2] memory reserves;
            reserves[0] = reservesA;
            reserves[1] = reservesB;
            output[i] = reserves;
        }
        return output;
    }
}
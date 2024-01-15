pragma solidity =0.6.6;

import "./ExampleSlidingWindowOracle.sol";
import "./IUniswapV2Factory.sol";

contract UniswapV2SlidingOracle is ExampleSlidingWindowOracle {
    constructor(IUniswapV2Factory uniswapFactory)
        public
        ExampleSlidingWindowOracle(address(uniswapFactory), 6 hours, 6)
    {}
}

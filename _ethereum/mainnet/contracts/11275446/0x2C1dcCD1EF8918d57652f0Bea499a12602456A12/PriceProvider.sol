
pragma solidity ^0.6.0;

import "./IStatisticProvider.sol";
import "./IUniswapV2Oracle.sol";

contract PriceProvider is IStatisticProvider {
    address immutable tokenA;
    address immutable tokenB;
    IUniswapV2Oracle immutable oracle;
    uint constant ONE = 10**18;

    constructor(address tokenA_, address tokenB_, address oracle_) public {
        tokenA = tokenA_;
        tokenB = tokenB_;
        oracle = IUniswapV2Oracle(oracle_);
    }

    function current() public view override returns (uint) {
        return oracle.current(
            tokenA,
            ONE,
            tokenB
        );
    }

}
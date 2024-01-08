contract IOracle {
    uint public PERIOD;

    address public token0;
    address public token1;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public blockTimestampLast;

    uq112x112 public price0Average;
    uq112x112 public price1Average;

    function update () external {}

    function consult (address token, uint amountIn) external view returns (uint amountOut) {}

    struct uq112x112 {
        uint224 _x;
    }
}

interface IXPriceOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256);
}

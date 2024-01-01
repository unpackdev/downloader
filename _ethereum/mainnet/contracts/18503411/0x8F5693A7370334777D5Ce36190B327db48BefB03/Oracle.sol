interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract Oracle {
    AggregatorInterface public immutable usdOracle;

    constructor(AggregatorInterface _usdOracle) {
        usdOracle = _usdOracle;
    }

    function price() external view returns (int256) {
        return usdOracle.latestAnswer();
    }
}
interface IChainLinkOracle {
    function latestAnswer() external returns(uint256);
}
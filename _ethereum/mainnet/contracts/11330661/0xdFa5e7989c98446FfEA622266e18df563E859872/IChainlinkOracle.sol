pragma solidity 0.6.6;

abstract contract IChainlinkOracle {
    // prices returned to 8 decimal places
    function latestAnswer() external view virtual returns (int256);
}

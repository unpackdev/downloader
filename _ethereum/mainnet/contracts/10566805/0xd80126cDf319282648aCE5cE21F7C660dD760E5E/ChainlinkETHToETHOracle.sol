
// File: solidity/contracts/utility/interfaces/IChainlinkPriceOracle.sol

pragma solidity 0.4.26;

/*
    Chainlink Price Oracle interface
*/
interface IChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

// File: solidity/contracts/utility/ChainlinkETHToETHOracle.sol

pragma solidity 0.4.26;


/**
  * @dev Provides the trivial ETH/ETH rate to be used with other TKN/ETH rates
*/
contract ChainlinkETHToETHOracle is IChainlinkPriceOracle {
    int256 private constant ETH_RATE = 1;

    /**
      * @dev returns the trivial ETH/ETH rate.
      *
      * @return always returns the trivial rate of 1
    */
    function latestAnswer() external view returns (int256) {
        return ETH_RATE;
    }

    /**
      * @dev returns the trivial ETH/ETH update time.
      *
      * @return always returns current block's timestamp
    */
    function latestTimestamp() external view returns (uint256) {
        return now;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BFacetOwner.sol";
import "./LibAddress.sol";

contract AddressFacet is BFacetOwner {
    using LibAddress for address;

    event LogSetOracleAggregator(address indexed oracleAggregator);

    event LogSetGasPriceOracle(address indexed gasPriceOracle);

    function setOracleAggregator(address _oracleAggregator) external onlyOwner {
        _oracleAggregator.setOracleAggregator();
        emit LogSetOracleAggregator(_oracleAggregator);
    }

    function setGasPriceOracle(address _gasPriceOracle) external onlyOwner {
        _gasPriceOracle.setGasPriceOracle();
        emit LogSetGasPriceOracle(_gasPriceOracle);
    }

    function getOracleAggregator()
        public
        view
        returns (address oracleAggregator)
    {
        oracleAggregator = LibAddress.getOracleAggregator();
        require(
            oracleAggregator != address(0),
            "AddressFacet.getOracleAggregator: Address Zero"
        );
    }

    function getGasPriceOracle() public view returns (address gasPriceOracle) {
        gasPriceOracle = LibAddress.getGasPriceOracle();
        require(
            gasPriceOracle != address(0),
            "AddressFacet.getGasPriceOracle: Address Zero"
        );
    }
}

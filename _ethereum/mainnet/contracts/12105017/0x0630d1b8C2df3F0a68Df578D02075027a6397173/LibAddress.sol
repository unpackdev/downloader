// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library LibAddress {
    struct AddressStorage {
        address oracleAggregator;
        address gasPriceOracle;
    }

    bytes32 private constant _ADDRESS_STORAGE =
        keccak256("gelato.diamond.address.storage");

    function setOracleAggregator(address _oracleAggregator) internal {
        LibAddress.addressStorage().oracleAggregator = _oracleAggregator;
    }

    function setGasPriceOracle(address _gasPriceOracle) internal {
        LibAddress.addressStorage().gasPriceOracle = _gasPriceOracle;
    }

    function getOracleAggregator() internal view returns (address) {
        return addressStorage().oracleAggregator;
    }

    function getGasPriceOracle() internal view returns (address) {
        return addressStorage().gasPriceOracle;
    }

    function addressStorage()
        internal
        pure
        returns (AddressStorage storage ads)
    {
        bytes32 position = _ADDRESS_STORAGE;
        assembly {
            ads.slot := position
        }
    }
}

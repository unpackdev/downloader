// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibAddress {
    struct AddressStorage {
        address oracleAggregator;
    }

    bytes32 private constant _ADDRESS_STORAGE =
        keccak256("gelato.diamond.address.storage");

    function setOracleAggregator(address _oracleAggregator) internal {
        LibAddress.addressStorage().oracleAggregator = _oracleAggregator;
    }

    function getOracleAggregator() internal view returns (address) {
        return addressStorage().oracleAggregator;
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

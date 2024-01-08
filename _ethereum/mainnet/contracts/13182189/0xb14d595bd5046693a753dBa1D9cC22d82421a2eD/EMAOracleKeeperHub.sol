// SPDX-License-Identifier: GPL-v3-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IKeeperCompatible.sol";
import "./IEMAOracle.sol";

contract EMAOracleKeeperHub is IKeeperCompatible, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _oracles;
    address[] internal _dynamicArray; // A hack for implementing a array with modifiable length

    modifier useDynamicArray {
        _;
        delete _dynamicArray;
    }

    /**
        Oracle registration
     */
    function addOracle(address oracle) external onlyOwner {
        _oracles.add(oracle);
    }

    function removeOracle(address oracle) external onlyOwner {
        _oracles.remove(oracle);
    }

    /**
        Oracle getters
     */
    function numOracles() external view returns (uint256) {
        return _oracles.length();
    }

    function isOracle(address query) external view returns (bool) {
        return _oracles.contains(query);
    }

    function getOracleAt(uint256 index) external view returns (address) {
        return _oracles.at(index);
    }

    /**
        @inheritdoc IKeeperCompatible
     */
    function checkUpkeep(bytes calldata /*checkData*/)
        external
        override
        useDynamicArray
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] storage oraclesToUpdate = _dynamicArray;
        for (uint256 i = 0; i < _oracles.length(); i++) {
            IEMAOracle oracle = IEMAOracle(_oracles.at(i));
            (bool updated, ) = oracle.updateAndQuery();
            if (updated) {
                upkeepNeeded = true;

                oraclesToUpdate.push(address(oracle));
            }
        }
        if (upkeepNeeded) {
            performData = abi.encode(oraclesToUpdate);
        }
    }

    /**
        @inheritdoc IKeeperCompatible
     */
    function performUpkeep(bytes calldata performData) external override {
        address[] memory oraclesToUpdate = abi.decode(performData, (address[]));
        for (uint256 i = 0; i < oraclesToUpdate.length; i++) {
            IEMAOracle oracle = IEMAOracle(oraclesToUpdate[i]);
            (bool updated, ) = oracle.updateAndQuery();
            require(updated, "EMAOracleKeeperHub: oracle not updated");
        }
    }
}

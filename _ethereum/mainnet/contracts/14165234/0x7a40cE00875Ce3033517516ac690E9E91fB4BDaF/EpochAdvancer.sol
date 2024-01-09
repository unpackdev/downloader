// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ISmartAlpha.sol";

contract EpochAdvancer is Ownable {
    address[] public pools;
    uint256 public numberOfPools;

    uint256 public gasPerPool; // on mainnet it should be about 400_000

    constructor(address[] memory addrs, uint256 _gasPerPool){
        gasPerPool = _gasPerPool;
        if (addrs.length > 0) {
            addPools(addrs);
        }
    }

    function addPool(address poolAddress) public onlyOwner {
        require(poolAddress != address(0), "invalid address");

        pools.push(poolAddress);
        numberOfPools++;
    }

    function removePool(address poolAddress) public onlyOwner {
        require(poolAddress != address(0), "invalid address");

        for (uint256 i = 0; i < numberOfPools; i++) {
            if (pools[i] == poolAddress) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                numberOfPools--;
                return;
            }
        }
    }

    function addPools(address[] memory addrs) public onlyOwner {
        require(addrs.length > 0, "invalid array");

        for (uint256 i = 0; i < addrs.length; i++) {
            addPool(addrs[i]);
        }
    }

    function removePools(address[] memory addrs) public onlyOwner {
        require(addrs.length > 0, "invalid array");

        for (uint256 i = 0; i < addrs.length; i++) {
            removePool(addrs[i]);
        }
    }

    function setGasPerPool(uint256 _newGasPerPool) public onlyOwner {
        gasPerPool = _newGasPerPool;
    }

    function advanceEpochs() public {
        for (uint256 i = 0; i < pools.length; i++) {
            ISmartAlpha sa = ISmartAlpha(pools[i]);

            if (sa.getCurrentEpoch() > sa.epoch()) {
                if (gasleft() < gasPerPool) {
                    break;
                }

                sa.advanceEpoch();
            }
        }
    }

    function getPools() public view returns (address[] memory) {
        address[] memory result = new address[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            result[i] = pools[i];
        }

        return result;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool, bytes memory) {
        bool upkeepNeeded;

        for (uint256 i = 0; i < pools.length; i++) {
            ISmartAlpha sa = ISmartAlpha(pools[i]);

            if (sa.getCurrentEpoch() > sa.epoch()) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        advanceEpochs();
    }
}

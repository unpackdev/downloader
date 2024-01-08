// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ISmartAlpha.sol";

contract EpochAdvancer is Ownable {
    address[] public pools;
    uint256 public numberOfPools;

    constructor(address[] memory addrs) {
        if (addrs.length > 0) {
            addPools(addrs);
        }
    }

    function addPool(address poolAddress) public onlyOwner {
        require(poolAddress != address(0), "invalid address");

        pools.push(poolAddress);
        numberOfPools++;
    }

    function addPools(address[] memory addrs) public onlyOwner {
        require(addrs.length > 0, "invalid array");

        for (uint256 i = 0; i < addrs.length; i++) {
            addPool(addrs[i]);
        }
    }

    function advanceEpochs() public {
        for (uint256 i = 0; i < pools.length; i++) {
            ISmartAlpha sa = ISmartAlpha(pools[i]);

            if (sa.getCurrentEpoch() > sa.epoch()) {
                sa.advanceEpoch();
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./CegaStorage.sol";

contract DCSBaseInterfaces is CegaStorage {
    function getVaults() external view returns (address[] memory) {
        CegaGlobalStorage storage s = getStorage();
        return s.dcsProducts[0].vaults;
    }

    function addVaults(address[] memory vaults) external {
        CegaGlobalStorage storage s = getStorage();
        for (uint256 i = 0; i < vaults.length; i++) {
            s.dcsProducts[0].vaults.push(vaults[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./AirdropHelper.sol";
import "./ContractSafe.sol";

/// @title Airdrop Helper for Lazy Lions
/// @author Akshat Mittal
contract LazyAirdrop is AirdropHelper, ContractSafe {
    function isTargetContract(address target) public view returns (bool) {
        return ContractSafe.isContract(target);
    }

    function isTargetsContract(address[] memory targets) public view returns (bool[] memory _res) {
        _res = new bool[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            _res[i] = isTargetContract(targets[i]);
        }
    }
}

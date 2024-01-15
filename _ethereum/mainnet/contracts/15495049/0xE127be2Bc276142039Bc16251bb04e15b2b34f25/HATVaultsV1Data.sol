// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IHATVaultsV1.sol";
import "./IHATVaultsData.sol";

contract HATVaultsV1Data is IHATVaultsData {
    IHATVaultsV1 public hatVaults;

    constructor(IHATVaultsV1 _hatVaults) {
        hatVaults = _hatVaults;
    }

    function getTotalShares(uint256 _pid) external view returns (uint256) {
        return hatVaults.poolInfo(_pid).totalUsersAmount;
    }

    function getShares(uint256 _pid, address _user) external view returns (uint256) {
        return hatVaults.userInfo(_pid, _user).amount;
    }
}
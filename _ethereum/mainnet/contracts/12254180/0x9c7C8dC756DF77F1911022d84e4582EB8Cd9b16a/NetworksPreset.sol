// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";

abstract contract NetworksPreset {
    using SafeMath for uint256;

    uint256 public networkThis;
    uint256 public networksTotal;

    struct NetworkInfo {
        bool enabled;
        string description;
    }
    mapping(uint256 => NetworkInfo) public networkInfo;

    function isNetworkEnabled(uint256 netId) public view returns (bool) {
        return networkInfo[netId].enabled;
    }

    function _addNetwork(string memory description) internal {
        networkInfo[networksTotal].enabled = false;
        networkInfo[networksTotal].description = description;
        networksTotal = networksTotal.add(1);
    }

    function _setNetworkStatus(uint256 netId, bool status) internal {
        networkInfo[netId].enabled = status;
    }
}

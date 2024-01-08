//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TiersV1.sol";

contract TiersInfo {
    TiersV1 public tiers;

    constructor(address _tiers) {
        tiers = TiersV1(_tiers);
    }

    function totals(uint count) public view returns (uint[] memory) {
        uint[] memory list = new uint[](count);
        for (uint i = 0; i < count; i++) {
            try tiers.users(i) returns (address user) {
                if (user != address(0)) {
                    (, uint total) = tiers.userInfoTotal(user);
                    list[i] = total;
                }
            } catch {
                break;
            }
        }
        return list;
    }
}
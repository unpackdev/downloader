//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Storage {
    struct VIPStats {
        uint256 startedAt;
        uint256 expiredAt;
    }
    mapping(address => VIPStats) internal vipMap;
    address public checkoutContract;
    address[] internal vips;
}

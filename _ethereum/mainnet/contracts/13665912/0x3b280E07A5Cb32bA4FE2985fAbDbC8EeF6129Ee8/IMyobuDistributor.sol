// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyobuDistributor {
    struct DistributeTo {
        address addr;
        uint256 percentage;
    }
    event DistributeToChanged(DistributeTo[] _distributeTo);

    function distributeTo(uint256 index)
        external
        view
        returns (DistributeTo memory);

    function distributeToCount() external view returns (uint256);

    event Distributed(uint256 amount, address sender);

    function distribute() external;
}

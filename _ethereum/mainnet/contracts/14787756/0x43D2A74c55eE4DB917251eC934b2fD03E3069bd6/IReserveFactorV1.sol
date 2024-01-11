// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IReserveFactorV1 {
    function distribute(address[] memory) external;

    function upgradeToAndCall(address, bytes calldata) external payable;

    function getDistribution() external view returns (address[] memory, uint256[] memory);
}

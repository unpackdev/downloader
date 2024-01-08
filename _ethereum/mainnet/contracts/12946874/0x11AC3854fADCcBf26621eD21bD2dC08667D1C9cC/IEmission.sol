// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface IEmission {
    event SetDistribution(uint distributionInterval, uint distributedPerInterval);

    function setDistribution(uint _distributionInterval, uint _distributedPerInterval) external;
    function withdraw() external;
    function withdrawable() external view returns (uint);
    function distributionInterval() external view returns (uint);
    function distributedPerInterval() external view returns (uint);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBulletOracle {
    function getMaxBullet(address _sender, uint64 _originChain, address _collection) external view returns (uint64);

    function baseLimit() external view returns (uint64);

    function getBulletLimitBySender(address _sender) external view returns (uint64);

    function getBulletLimitByCollection(uint64 _originChain, address _collection) external view returns (uint64);
}

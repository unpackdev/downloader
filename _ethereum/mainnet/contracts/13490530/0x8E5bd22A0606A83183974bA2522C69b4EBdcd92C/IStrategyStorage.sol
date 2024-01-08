// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStrategyStorage {
    function bank() external view returns (address);

    function underlying() external view returns (address);

    function derivative() external view returns (address);

    function reward() external view returns (address);

    // function investedBalance() external view returns (uint256);

    // function invest() external;

    // function withdraw(uint256 amount) external returns (uint256);

    // function withdrawAll() external;
}

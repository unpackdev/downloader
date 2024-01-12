// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IPoolFactory {
    function poolRegistry() external view returns (address);

    function createNewPool(uint256 _poolId)
        external
        returns (
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim
        );
}

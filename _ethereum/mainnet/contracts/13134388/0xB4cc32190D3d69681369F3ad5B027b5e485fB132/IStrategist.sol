// CompoundVault.sol
// SPDX-License-Identifier: MIT

/**
        IDX Digital Labs Earning Protocol.
        Compound Vault Strategist
        Gihub :
        Testnet : 

 */
pragma solidity ^0.8.0;

interface StrategistProxy {
    
    function _getVaultReturn(address vaultAddress, address account)
        external
        view
        returns (uint256[] memory strategistData);

    function updateCompoundVault(address vault) external;

    function getCurrentRate(address vaultAddress)
        external
        view
        returns (uint256 price);
}
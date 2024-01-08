// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakeTONProxyFactory {
    /// @dev Create a StakeTONProxy that can stake TON.
    /// @param _logic the logic contract address used in proxy
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _registry the registry address
    /// @param _intdata the array of [saleStartBlock, startBlock, periodBlocks]
    /// @param owner  owner address
    /// @return contract address
    function deploy(
        address _logic,
        address[4] calldata _addr,
        address _registry,
        uint256[3] calldata _intdata,
        address owner
    ) external returns (address);
}

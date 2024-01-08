//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeContractFactory {
    /// @dev Create a stake contract that can stake TON.
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _registry  the registry address
    /// @param _intdata the array of [saleStartBlock, startBlock, periodBlocks]
    /// @param owner  owner address
    /// @return contract address
    function create(
        address[4] calldata _addr,
        address _registry,
        uint256[3] calldata _intdata,
        address owner
    ) external returns (address);
}

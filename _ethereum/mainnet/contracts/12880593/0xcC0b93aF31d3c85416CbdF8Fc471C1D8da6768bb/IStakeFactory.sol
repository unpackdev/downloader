//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeFactory {
    /// @dev Create a stake contract that calls the desired stake factory according to stakeType
    /// @param stakeType if 0, stakeTONFactory, else if 1 , stakeSimpleFactory , else if 2, stakeUniswapV3Factory
    /// @param _addr array of [token, paytoken, vault, _defiAddr]
    /// @param registry  registry address
    /// @param _intdata array of [saleStartBlock, startBlock, periodBlocks]
    /// @return contract address
    function create(
        uint256 stakeType,
        address[4] calldata _addr,
        address registry,
        uint256[3] calldata _intdata
    ) external returns (address);

    /// @dev Set factory address by StakeType
    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStakeFactory.sol";

import "./IStakeContractFactory.sol";
import "./AccessibleCommon.sol";

/// @title A factory that calls the desired stake factory according to stakeType
contract StakeFactory is IStakeFactory, AccessibleCommon {
    mapping(uint256 => address) public factory;

    modifier nonZero(address _addr) {
        require(_addr != address(0), "StakeFactory: zero");
        _;
    }

    /// @dev constructor of StakeFactory
    /// @param _stakeSimpleFactory the logic address used in StakeSimpleFactory
    /// @param _stakeTONFactory the logic address used in StakeTONFactory
    /// @param _stakeUniswapV3Factory the logic address used in StakeUniswapV3Factory
    constructor(
        address _stakeSimpleFactory,
        address _stakeTONFactory,
        address _stakeUniswapV3Factory
    ) {
        require(_stakeTONFactory != address(0), "StakeFactory: init fail");

        factory[0] = _stakeTONFactory;
        //factory[1] = _stakeSimpleFactory;
        //factory[2] = _stakeUniswapV3Factory;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Set factory address by StakeType
    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP, may continue to be added.
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external
        override
        onlyOwner
        nonZero(_factory)
    {
        factory[_stakeType] = _factory;
    }

    /// @dev Create a stake contract that calls the desired stake factory according to stakeType
    /// @param stakeType if 0, stakeTONFactory, else if 1 , stakeSimpleFactory , else if 2, stakeUniswapV3Factory
    /// @param _addr array of [token, paytoken, vault, _defiAddr]
    ///         or when stakeTyoe ==2 , [tos,0 , vault, 0 ]
    /// @param registry  registry address
    /// @param _intdata array of [saleStartBlock, startBlock, periodBlocks]
    ///         or when stakeTyoe ==2 , [cap, rewardPerBlock, 0]
    /// @return contract address
    function create(
        uint256 stakeType,
        address[4] calldata _addr,
        address registry,
        uint256[3] calldata _intdata
    ) external override onlyOwner returns (address) {
        require(
            factory[stakeType] != address(0),
            "StakeFactory: zero factory "
        );
        require(_addr[2] != address(0), "StakeFactory: vault zero");

        address proxy =
            IStakeContractFactory(factory[stakeType]).create(
                _addr,
                registry,
                _intdata,
                msg.sender
            );

        require(proxy != address(0), "StakeFactory: proxy zero");

        return proxy;
    }
}

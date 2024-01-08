// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStakeUniswapV3Factory.sol";
import "./StakeUniswapV3Proxy.sol";
import "./AccessRoleCommon.sol";

/// @title A factory that creates a stake contract that can function as a DeFi function
contract StakeUniswapV3Factory is AccessRoleCommon, IStakeUniswapV3Factory {
    address public stakeUniswapV3Logic;
    address public coinageFactory;

    /// @dev constructor of StakeCoinageFactory
    /// @param _stakeUniswapV3Logic the logic address used in stakeUniswapV3
    /// @param _coinageFactory the _coinage factory address
    constructor(address _stakeUniswapV3Logic, address _coinageFactory) {
        require(
            _stakeUniswapV3Logic != address(0) && _coinageFactory != address(0),
            "StakeUniswapV3Factory: logic zero"
        );
        stakeUniswapV3Logic = _stakeUniswapV3Logic;
        coinageFactory = _coinageFactory;
    }

    /// @dev Create a stake contract that can operate the staked amount as a DeFi project.
    /// @param _addr array of [tos, 0, vault, 0 ]
    /// @param _registry  registry address
    /// @param _intdata array of [cap, rewardPerBlock, 0]
    /// @param owner  owner address
    /// @return contract address
    function create(
        address[4] calldata _addr,
        address _registry,
        uint256[3] calldata _intdata,
        address owner
    ) external override returns (address) {
        StakeUniswapV3Proxy proxy =
            new StakeUniswapV3Proxy(stakeUniswapV3Logic, coinageFactory);
        require(
            address(proxy) != address(0),
            "StakeUniswapV3Factory: proxy zero"
        );

        proxy.setInit(_addr, _registry, _intdata);
        proxy.deployCoinage();

        proxy.grantRole(ADMIN_ROLE, owner);
        proxy.revokeRole(ADMIN_ROLE, address(this));

        return address(proxy);
    }
}

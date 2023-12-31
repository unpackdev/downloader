//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AggregatorV3Interface.sol";
import "./IERC20Upgradeable.sol";
import "./IUniswapV3Pool.sol";
import "./IPoolAddressesProvider.sol";

library DataTypesLib {
    struct UserVault {
        bool exists;
        uint256 token;
    }

    struct UserVaultInfo {
        address user;
        uint256 token;
    }

    struct State {
        address factory;
        IUniswapV3Pool pool;
        IERC20Upgradeable token0;
        IERC20Upgradeable token1;
        int24 lowerTick;
        int24 upperTick;
        int24 tickSpacing;
        bool inThePosition;
        bool isToken0GHO;
        uint8 decimals0;
        uint8 decimals1;
        uint8 vaultDecimals;
        uint16 managingFee;
        uint16 performanceFee;
        uint256 managerBalance0;
        uint256 managerBalance1;
        IPoolAddressesProvider poolAddressesProvider;
        AggregatorV3Interface collateralTokenPriceFeed;
        AggregatorV3Interface ghoPriceFeed;
        mapping(address => UserVault) vaults;
        address[] users;
    }
}

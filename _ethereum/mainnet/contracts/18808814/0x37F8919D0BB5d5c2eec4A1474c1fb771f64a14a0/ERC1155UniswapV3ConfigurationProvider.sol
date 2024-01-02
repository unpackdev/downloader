// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC1155ConfigurationProvider.sol";
import "./IERC1155UniswapV3Wrapper.sol";
import "./INonfungiblePositionManager.sol";
import "./DataTypes.sol";
import "./IPool.sol";
import "./ReserveConfiguration.sol";
import "./Math.sol";

contract ERC1155UniswapV3ConfigurationProvider is IERC1155ConfigurationProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IPool public immutable pool;
    IERC1155UniswapV3Wrapper public immutable wrapper;
    INonfungiblePositionManager public immutable positionManager;

    constructor(IPool _pool, IERC1155UniswapV3Wrapper _wrapper) {
        pool = _pool;
        wrapper = _wrapper;
        positionManager = _wrapper.positionManager();
    }

    function getERC1155ReserveConfig(uint256 tokenId)
        external
        view
        returns (DataTypes.ERC1155ReserveConfiguration memory)
    {
        (,, address token0, address token1,,,,,,,,) = positionManager.positions(tokenId);

        DataTypes.ReserveConfigurationMap memory config0 = pool.getConfiguration(token0);
        DataTypes.ReserveConfigurationMap memory config1 = pool.getConfiguration(token1);

        (bool isActive0, bool isFrozen0,, bool isPaused0) = config0.getFlags();
        (bool isActive1, bool isFrozen1,, bool isPaused1) = config1.getFlags();

        uint256 liquidationThreshold = Math.min(config0.getLiquidationThreshold(), config1.getLiquidationThreshold());
        uint256 liquidationBonus = Math.max(config0.getLiquidationBonus(), config1.getLiquidationBonus());
        uint256 ltv = Math.min(config0.getLtv(), config1.getLtv());

        return DataTypes.ERC1155ReserveConfiguration({
            isActive: isActive0 && isActive1,
            isFrozen: isFrozen0 || isFrozen1,
            isPaused: isPaused0 || isPaused1,
            ltv: ltv,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: liquidationBonus
        });
    }
}

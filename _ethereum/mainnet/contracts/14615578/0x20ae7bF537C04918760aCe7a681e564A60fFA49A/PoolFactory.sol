// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./StrConcat.sol";
import "./IPoolFactory.sol";
import "./IDeployer01.sol";
import "./SystemSettings.sol";

import "./ERC20.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV2Factory.sol";

contract PoolFactory is IPoolFactory, SystemSettings {
    mapping(address => mapping(address => mapping(bool => address))) public override pools;

    address private _uniFactoryV3;
    address private _uniFactoryV2;
    address private _sushiFactory;
    address private _deployer01;

    constructor(address uniFactoryV3,
        address uniFactoryV2,
        address sushiFactory,
        address deployer01,
        address deployer02) SystemSettings(deployer02) {
        _uniFactoryV3 = uniFactoryV3;
        _uniFactoryV2 = uniFactoryV2;
        _sushiFactory = sushiFactory;
        _deployer01 = deployer01;
    }

    function createPoolFromUni(address tradeToken, address poolToken, uint24 fee, bool reverse) external override {
        address uniPool;
        uint8 oracle;

        if (fee == 0) {
            IUniswapV2Factory uniswap = IUniswapV2Factory(_uniFactoryV2);
            uniPool = uniswap.getPair(tradeToken, poolToken);
            oracle = 1;
        } else {
            IUniswapV3Factory uniswap = IUniswapV3Factory(_uniFactoryV3);
            uniPool = uniswap.getPool(tradeToken, poolToken, fee);
            oracle = 0;
        }

        require(uniPool != address(0), "trade pair not found in uni swap");
        require(pools[poolToken][uniPool][reverse] == address(0), "pool already exists");

        string memory tradePair = StrConcat.strConcat(ERC20(tradeToken).symbol(), ERC20(poolToken).symbol());
        (address pool, address debt) = IDeployer01(_deployer01).deploy(poolToken, uniPool, address(this), tradePair, reverse, oracle);
        pools[poolToken][uniPool][reverse] = pool;

        emit CreatePoolFromUni(tradeToken, poolToken, uniPool, pool, debt, tradePair, fee, reverse);
    }

    function createPoolFromSushi(address tradeToken, address poolToken, bool reverse) external override {
        IUniswapV2Factory sushi = IUniswapV2Factory(_sushiFactory);
        address sushiPool = sushi.getPair(tradeToken, poolToken);

        require(sushiPool != address(0), "trade pair not found in sushi swap");
        require(pools[poolToken][sushiPool][reverse] == address(0), "pool already exists");

        string memory tradePair = StrConcat.strConcat(ERC20(tradeToken).symbol(), ERC20(poolToken).symbol());
        (address pool, address debt) = IDeployer01(_deployer01).deploy(poolToken, sushiPool, address(this), tradePair, reverse, 2);
        pools[poolToken][sushiPool][reverse] = pool;

        emit CreatePoolFromSushi(tradeToken, poolToken, sushiPool, pool, debt, tradePair, reverse);
    }
}

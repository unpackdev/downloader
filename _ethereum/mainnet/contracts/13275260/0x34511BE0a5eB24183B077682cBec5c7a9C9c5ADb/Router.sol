pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV3Pool.sol";

import "./IFactory.sol";
import "./IVault.sol";
import "./IRouter.sol";

contract Router is IRouter, ReentrancyGuard {
    using SafeMath for uint256;

    IFactory public override factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }

    /// @inheritdoc IRouter
    function newBaseLiquidity(
        int24 _baseLower,
        int24 _baseUpper,
        uint8 _percentage,
        bool swapEnabled
    ) external override nonReentrant {
        IVault vault = _getVault(msg.sender);
        newLiquidity(
            vault,
            _baseLower,
            _baseUpper,
            vault.baseLower(),
            vault.baseUpper(),
            _percentage,
            swapEnabled
        );
        vault.setBaseTicks(_baseLower, _baseUpper);

        emit RebalanceBaseLiqudity(address(vault), _baseLower, _baseUpper, _percentage);
    }

    /// @inheritdoc IRouter
    function newLimitLiquidity(
        int24 _limitLower,
        int24 _limitUpper,
        uint8 _percentage,
        bool swapEnabled
    ) external override nonReentrant {
        IVault vault = _getVault(msg.sender);
        newLiquidity(
            vault,
            _limitLower,
            _limitUpper,
            vault.limitLower(),
            vault.limitUpper(),
            _percentage,
            swapEnabled
        );
        vault.setLimitTicks(_limitLower, _limitUpper);

        emit RebalanceLimitLiqudity(address(vault), _limitLower, _limitUpper, _percentage);
    }

    function newLiquidity(
        IVault vault,
        int24 tickLower,
        int24 tickUpper,
        int24 oldTickLower,
        int24 oldTickUpper,
        uint8 percentage,
        bool swapEnabled
    ) internal {
        require(percentage <= 100, "percentage");
        vault.poke(oldTickLower, oldTickUpper);
        (uint128 oldLiquidity, , , , ) = vault.position(
            oldTickLower,
            oldTickUpper
        );
        if (oldLiquidity > 0) {
            vault.burnAndCollect(oldTickLower, oldTickUpper, oldLiquidity);
        }
        if (percentage > 0) {
            uint256 balance0 = vault.getBalance0();
            uint256 balance1 = vault.getBalance1();

            vault.mintOptimalLiquidity(
                tickLower,
                tickUpper,
                balance0.mul(percentage).div(100),
                balance1.mul(percentage).div(100),
                swapEnabled
            );
        }
    }

    /// @inheritdoc IRouter
    function getBaseAmounts(address _vault)
        public
        view
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        IVault vault = IVault(_vault);
        (liquidity, , , , ) = vault.position(
            vault.baseLower(),
            vault.baseUpper()
        );

        (amount0, amount1) = vault.getPositionAmounts(
            vault.baseLower(),
            vault.baseUpper()
        );
    }

    /// @inheritdoc IRouter
    function getLimitAmounts(address _vault)
        public
        view
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        IVault vault = IVault(_vault);
        (liquidity, , , , ) = vault.position(
            vault.limitLower(),
            vault.limitUpper()
        );

        (amount0, amount1) = vault.getPositionAmounts(
            vault.limitLower(),
            vault.limitUpper()
        );
    }

    /// @inheritdoc IRouter
    function getBaseTicks(address _vault)
        external
        view
        override
        returns (int24, int24)
    {
        IVault vault = IVault(_vault);
        return (vault.baseLower(), vault.baseUpper());
    }

    /// @inheritdoc IRouter
    function getLimitTicks(address _vault)
        external
        view
        override
        returns (int24, int24)
    {
        IVault vault = IVault(_vault);
        return (vault.limitLower(), vault.limitUpper());
    }

    /// @inheritdoc IRouter
    function compoundFee(address _vault) public override {
        IVault vault = IVault(_vault);
        vault.compoundFee();
    }

    // modifier onlyStrategy(address _manager) {
    //     require(
    //         factory.managerVault(_manager) != address(0),
    //         "Router : onlyStrategy :: tx sender needs to be a valid strategy manager"
    //     );
    //     _;
    // }

    /// @dev Retrieves the vault for msg.sender by fetching from factory
    function _getVault(address _manager) internal view returns (IVault vault) {
        address _vault = factory.managerVault(_manager);

        // This should never fail, but just in case
        require(
            _vault != address(0),
            "Router : _getVault :: PANIC! SM has no valid vault"
        );
        return IVault(_vault);
    }
}

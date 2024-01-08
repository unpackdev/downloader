// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IBRouter.sol";
import "./IOilerOptionBase.sol";
import "./IBPool.sol";

import "./OilerRegistry.sol";

import "./ProxyFactory.sol";

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract OilerOptionBaseFactory is Ownable, ProxyFactory {
    event Created(address _optionAddress, bytes32 _symbol);

    struct OptionInitialLiquidity {
        address collateral;
        uint256 collateralAmount;
        address option;
        uint256 optionsAmount;
    }
    /**
     * @dev Stores address of the registry.
     */
    OilerRegistry public immutable registry;

    /**
     * @dev Address on which proxy logic is deployed.
     */
    address public optionLogicImplementation;

    /**
     * @dev Balancer pools bRouter address.
     */
    IBRouter public immutable bRouter;

    /**
     * @param _factoryOwner - Factory owner.
     * @param _registryAddress - Oiler options registry address.
     * @param _optionLogicImplementation - Proxy implementation address.
     */
    constructor(
        address _factoryOwner,
        address _registryAddress,
        address _bRouter,
        address _optionLogicImplementation
    ) Ownable() {
        Ownable.transferOwnership(_factoryOwner);
        bRouter = IBRouter(_bRouter);
        registry = OilerRegistry(_registryAddress);
        optionLogicImplementation = _optionLogicImplementation;
    }

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external virtual returns (address optionAddress);

    /**
     * @dev Allows factory owner to remove liquidity from pool.
     * @param _option - option liquidity pool to be withdrawn..
     */
    function removeOptionsPoolLiquidity(address _option) external onlyOwner {
        _removeOptionsPoolLiquidity(_option);
    }

    function isClone(address _query) external view returns (bool) {
        return _isClone(optionLogicImplementation, _query);
    }

    function _createOption() internal returns (address) {
        return _createClone(optionLogicImplementation);
    }

    /**
     * @dev Transfers collateral from msg.sender to contract.
     * @param _collateral - option collateral.
     * @param _collateralAmount - collateral amount to be transfered.
     */
    function _pullInitialLiquidityCollateral(address _collateral, uint256 _collateralAmount) internal {
        require(
            IERC20(_collateral).transferFrom(msg.sender, address(this), _collateralAmount),
            "OilerOptionBaseFactory: ERC20 transfer failed"
        );
    }

    /**
     * @dev Initialized a new balancer liquidity pool by providing to it option token and collateral.
     * @notice creates a new liquidity pool.
     * @notice during initialization some options are written and provided to the liquidity pool.
     * @notice pulls collateral.
     * @param _initialLiquidity - See {OptionInitialLiquidity}.
     */
    function _initializeOptionsPool(OptionInitialLiquidity memory _initialLiquidity) internal {
        // Approve option to pull collateral while writing option.
        require(
            IERC20(_initialLiquidity.collateral).approve(_initialLiquidity.option, _initialLiquidity.optionsAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, option"
        );

        // Approve bRouter to pull collateral.
        require(
            IERC20(_initialLiquidity.collateral).approve(address(bRouter), _initialLiquidity.collateralAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, bRouter"
        );

        // Approve bRouter to pull written options.
        require(
            IERC20(_initialLiquidity.option).approve(address(bRouter), _initialLiquidity.optionsAmount),
            "OilerOptionBaseFactory: ERC20 approval failed, bRouter"
        );

        // Pull liquidity required to write an option.
        _pullInitialLiquidityCollateral(
            address(IOilerOptionBase(_initialLiquidity.option).collateralInstance()),
            _initialLiquidity.optionsAmount
        );

        // Write the option.
        IOilerOptionBase(_initialLiquidity.option).write(_initialLiquidity.optionsAmount);

        // Add liquidity.
        bRouter.addLiquidity(
            _initialLiquidity.option,
            _initialLiquidity.collateral,
            _initialLiquidity.optionsAmount,
            _initialLiquidity.collateralAmount
        );
    }

    /**
     * @dev Removes liquidity provided while option creation.
     * @notice withdraws remaining in pool options and collateral.
     * @notice if option is still active reverts.
     * @notice once liquidity is removed the pool becomes unusable.
     * @param _option - option liquidity pool to be withdrawn.
     */
    function _removeOptionsPoolLiquidity(address _option) internal {
        require(
            !IOilerOptionBase(_option).isActive(),
            "OilerOptionBaseFactory.removeOptionsPoolLiquidity: option still active"
        );
        address optionCollateral = address(IOilerOptionBase(_option).collateralInstance());

        IBPool pool = bRouter.getPoolByTokens(_option, optionCollateral);

        require(
            pool.approve(address(bRouter), pool.balanceOf(address(this))),
            "OilerOptionBaseFactory.removeOptionsPoolLiquidity: approval failed"
        );

        uint256[] memory amounts = bRouter.removeLiquidity(_option, optionCollateral, pool.balanceOf(address(this)));

        require(IERC20(_option).transfer(msg.sender, amounts[0]), "ERR_ERC20_FAILED");
        require(IERC20(optionCollateral).transfer(msg.sender, amounts[1]), "ERR_ERC20_FAILED");
    }
}

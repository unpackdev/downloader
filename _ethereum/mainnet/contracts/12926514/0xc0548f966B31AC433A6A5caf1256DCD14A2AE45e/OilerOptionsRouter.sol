// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./IERC20Permit.sol";

import "./IOilerRegistry.sol";
import "./IOilerOptionBase.sol";
import "./IOilerOptionsRouter.sol";
import "./IBRouter.sol";
import "./IBPool.sol";

contract OilerOptionsRouter is IOilerOptionsRouter {
    IOilerRegistry public immutable override registry;
    IBRouter public immutable override bRouter;

    constructor(IOilerRegistry _registry, IBRouter _bRouter) {
        registry = _registry;
        bRouter = _bRouter;
    }

    modifier onlyRegistry() {
        require(
            address(registry) == msg.sender,
            "OilerOptionsRouter.setUnlimitedApprovals, only the registry can set an unlimited approval"
        );
        _;
    }

    function write(IOilerOptionBase _option, uint256 _amount) external override {
        _writeOnBehalfOf(_option, _amount);
    }

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external override {
        _writeOnBehalfOfAndTransferWriterRights(_option, _amount);
        _addLiquidity(_option, _amount, _liquidityProviderCollateralAmount);
    }

    // Permittable versions of the above:

    /**
     * @notice permit signed deadline must be max uint.
     */
    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external override {
        _writeOnBehalfOfAndTransferWriterRightsPermittable(_option, _amount, _permit);
    }

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writeOnBehalfOfPermit,
        Permit calldata _liquidityAddPermit
    ) external override {
        _writePermittable(_option, _amount, _writeOnBehalfOfPermit);
        _addLiquidityPermittable(_option, _amount, _liquidityProviderCollateralAmount, _liquidityAddPermit);
    }

    // Restricted functions: onlyRegistry
    // This is supposed to be called by the registry when new option is being registered
    function setUnlimitedApprovals(IOilerOptionBase _option) external override onlyRegistry {
        _option.collateralInstance().approve(address(_option), type(uint256).max);

        _option.collateralInstance().approve(address(bRouter), type(uint256).max);

        _option.approve(address(bRouter), type(uint256).max);
    }

    // Internal functions below:

    /// @dev writes options where:
    /// @dev 1. router receives the options
    /// @dev 2. router receives writer rights
    function _write(IOilerOptionBase _option, uint256 _amount) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _amount),
            "OilerOptionsRouter.write, ERC20 transfer failed"
        );

        _option.write(_amount);
    }

    /// @dev writes options where:
    /// @dev 1. original msg.sender receives the options
    /// @dev 2. router receives writer rights
    function _writeOnBehalfOf(IOilerOptionBase _option, uint256 _amount) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _amount),
            "OilerOptionsRouter.write, ERC20 transfer failed"
        );

        _option.write(_amount, msg.sender);
    }

    /// @dev writes options where:
    /// @dev 1. router receives the options
    /// @dev 2. original msg.sender receives writer rights
    /// @dev the options most likely will be added to LP and LP tokens will be sent back to msg.sender
    function _writeOnBehalfOfAndTransferWriterRights(IOilerOptionBase _option, uint256 _amount) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _amount),
            "OilerOptionsRouter.write, ERC20 transfer failed"
        );

        _option.write(_amount, msg.sender, address(this));
    }

    function _addLiquidity(
        IOilerOptionBase _option,
        uint256 _optionsAmount,
        uint256 _liquidityProviderCollateralAmount
    ) internal {
        require(
            _option.collateralInstance().transferFrom(msg.sender, address(this), _liquidityProviderCollateralAmount),
            "OilerOptionsRouter:addLiquidity, ERC20 transfer failed"
        );
        bRouter.addLiquidity(
            address(_option),
            address(_option.collateralInstance()),
            _optionsAmount,
            _liquidityProviderCollateralAmount
        );

        // Transfer back to msg.sender returned tokens and LP tokens.
        require(
            _option.transfer(msg.sender, _option.balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, options return transfer failed"
        );

        require(
            _option.collateralInstance().transfer(msg.sender, _option.collateralInstance().balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, collateral return transfer failed"
        );

        IBPool pool = bRouter.getPoolByTokens(address(_option), address(_option.collateralInstance()));

        require(
            pool.transfer(msg.sender, pool.balanceOf(address(this))),
            "OilerOptionsRouter:addLiquidity, lbp tokens return failed"
        );
    }

    // TODO verify if is it ok that all 3 functions have same permit

    // Permittable versions of the above:
    function _writeOnBehalfOfAndTransferWriterRightsPermittable(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit memory _permit
    ) internal {
        IERC20Permit(address(_option.collateralInstance())).permit(
            msg.sender,
            address(this),
            _amount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );
        _writeOnBehalfOfAndTransferWriterRights(_option, _amount);
    }

    function _writeOnBehalfOfPermittable(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit memory _permit
    ) internal {
        IERC20Permit(address(_option.collateralInstance())).permit(
            msg.sender,
            address(this),
            _amount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );
        _writeOnBehalfOf(_option, _amount);
    }

    function _writePermittable(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit memory _permit
    ) internal {
        IERC20Permit(address(_option.collateralInstance())).permit(
            msg.sender,
            address(this),
            _amount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );
        _write(_option, _amount);
    }

    function _addLiquidityPermittable(
        IOilerOptionBase _option,
        uint256 _optionsAmount,
        uint256 _collateralAmount,
        Permit memory _permit
    ) internal {
        _option.collateralInstance().permit(
            msg.sender,
            address(this),
            _collateralAmount,
            type(uint256).max,
            _permit.v,
            _permit.r,
            _permit.s
        );

        _addLiquidity(_option, _optionsAmount, _collateralAmount);
    }
}

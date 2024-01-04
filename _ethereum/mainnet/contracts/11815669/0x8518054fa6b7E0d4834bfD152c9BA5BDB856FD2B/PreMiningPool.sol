// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";
import "./ILToken.sol";
import "./IMigratablePool.sol";
import "./IPreMiningPool.sol";
import "./SafeERC20.sol";
import "./MixedSafeMathWithUnit.sol";
import "./MigratablePool.sol";

/**
 * @title Deri Protocol PreMining PerpetualPool Implementation
 */
contract PreMiningPool is IMigratablePool, IPreMiningPool, MigratablePool {

    using MixedSafeMathWithUnit for uint256;
    using MixedSafeMathWithUnit for int256;
    using SafeERC20 for IERC20;

    // Trading symbol
    string private _symbol;

    // Base token contract, all settlements are done in base token
    IERC20  private _bToken;
    // Base token decimals
    uint256 private _bDecimals;
    // Liquidity provider token contract
    ILToken private _lToken;

    // Minimum amount requirement when add liquidity
    uint256 private _minAddLiquidity;
    // Redemption fee ratio when removing liquidity
    uint256 private _redemptionFeeRatio;

    // Total liquidity pool holds
    uint256 private _liquidity;

    bool private _mutex;
    // Locker to prevent reentry
    modifier _lock_() {
        require(!_mutex, "PerpetualPool: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @dev A dummy constructor, which deos not initialize any storage variables
     * A template will be deployed with no initialization and real pool will be cloned
     * from this template (same as create_forwarder_to mechanism in Vyper),
     * and use `initialize` to initialize all storage variables
     */
    constructor () {}

    /**
     * @dev See {IPreMiningPool}.{initialize}
     */
    function initialize(
        string memory symbol_,
        address[2] calldata addresses_,
        uint256[2] calldata parameters_
    ) public override {
        require(
            bytes(_symbol).length == 0 && _controller == address(0),
            "PerpetualPool: already initialized"
        );

        _controller = msg.sender;
        _symbol = symbol_;

        _bToken = IERC20(addresses_[0]);
        _bDecimals = _bToken.decimals();
        _lToken = ILToken(addresses_[1]);

        _minAddLiquidity = parameters_[0];
        _redemptionFeeRatio = parameters_[1];
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     */
    function approveMigration() public override _controller_ {
        require(
            _migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp,
            "PerpetualPool: migrationTimestamp not met yet"
        );
        // approve new pool to pull all base tokens from this pool
        _bToken.safeApprove(_migrationDestination, uint256(-1));
        // set lToken to new pool, after redirecting lToken to new pool,
        // this pool will stop functioning
        _lToken.setPool(_migrationDestination);
    }

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     */
    function executeMigration(address source) public override _controller_ {
        uint256 migrationTimestamp_ = IPreMiningPool(source).migrationTimestamp();
        address migrationDestination_ = IPreMiningPool(source).migrationDestination();
        require(
            migrationTimestamp_ != 0 && block.timestamp >= migrationTimestamp_,
            "PerpetualPool: migrationTimestamp not met yet"
        );
        require(
            migrationDestination_ == address(this),
            "PerpetualPool: executeMigration to not destination pool"
        );

        // migrate base token
        _bToken.safeTransferFrom(source, address(this), _bToken.balanceOf(source));
        // migrate state values
        _liquidity = IPreMiningPool(source).getStateValues();

        emit ExecuteMigration(_migrationTimestamp, source, address(this));
    }

    /**
     * @dev See {IPreMiningPool}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IPreMiningPool}.{getAddresses}
     */
    function getAddresses() public view override returns (
        address bToken,
        address lToken
    ) {
        return (
            address(_bToken),
            address(_lToken)
        );
    }

    /**
     * @dev See {IPreMiningPool}.{getParameters}
     */
    function getParameters() public view override returns (
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio
    ) {
        return (
            _minAddLiquidity,
            _redemptionFeeRatio
        );
    }

    /**
     * @dev See {IPreMiningPool}.{getStateValues}
     */
    function getStateValues() public view override returns (
        uint256 liquidity
    ) {
        return _liquidity;
    }


    //================================================================================
    // Pool interactions
    //================================================================================

    /**
     * @dev See {IPreMiningPool}.{addLiquidity}
     */
    function addLiquidity(uint256 bAmount) public override {
        _addLiquidity(bAmount);
    }

    /**
     * @dev See {IPreMiningPool}.{removeLiquidity}
     */
    function removeLiquidity(uint256 lShares) public override {
        _removeLiquidity(lShares);
    }

    //================================================================================
    // Critical Logic
    //================================================================================

    /**
     * @dev Low level addLiquidity implementation
     */
    function _addLiquidity(uint256 bAmount) internal _lock_ {
        require(
            bAmount >= _minAddLiquidity,
            "PerpetualPool: add liquidity less than minimum requirement"
        );
        require(
            bAmount.reformat(_bDecimals) == bAmount,
            "PerpetualPool: _addLiquidity bAmount not valid"
        );

        bAmount = _deflationCompatibleSafeTransferFrom(msg.sender, address(this), bAmount);

        uint256 poolDynamicEquity = _liquidity;
        uint256 totalSupply = _lToken.totalSupply();
        uint256 lShares;
        if (totalSupply == 0) {
            lShares = bAmount;
        } else {
            lShares = bAmount.mul(totalSupply).div(poolDynamicEquity);
        }

        _lToken.mint(msg.sender, lShares);
        _liquidity = _liquidity.add(bAmount);

        emit AddLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev Low level removeLiquidity implementation
     */
    function _removeLiquidity(uint256 lShares) internal _lock_ {
        require(lShares > 0, "PerpetualPool: remove 0 liquidity");
        uint256 balance = _lToken.balanceOf(msg.sender);
        require(
            lShares == balance || balance.sub(lShares) >= 10**18,
            "PerpetualPool: remaining liquidity shares must be 0 or at least 1"
        );

        uint256 poolDynamicEquity = _liquidity;
        uint256 totalSupply = _lToken.totalSupply();
        uint256 bAmount = lShares.mul(poolDynamicEquity).div(totalSupply);
        if (lShares < totalSupply) {
            bAmount = bAmount.sub(bAmount.mul(_redemptionFeeRatio));
        }
        bAmount = bAmount.reformat(_bDecimals);

        _liquidity = _liquidity.sub(bAmount);

        _lToken.burn(msg.sender, lShares);
        _bToken.safeTransfer(msg.sender, bAmount.rescale(_bDecimals));

        emit RemoveLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev safeTransferFrom for base token with deflation protection
     * Returns the actual received amount in base token (as base 10**18)
     */
    function _deflationCompatibleSafeTransferFrom(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 preBalance = _bToken.balanceOf(to);
        _bToken.safeTransferFrom(from, to, amount.rescale(_bDecimals));
        uint256 curBalance = _bToken.balanceOf(to);

        uint256 a = curBalance.sub(preBalance);
        uint256 b = 10**18;
        uint256 c = a * b;
        require(c / b == a, "PreMiningPool: _deflationCompatibleSafeTransferFrom multiplication overflows");

        uint256 actualReceivedAmount = c / (10 ** _bDecimals);
        return actualReceivedAmount;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./ILiquidityGauge.sol";
import "./IGUniRouter.sol";
import "./IGUniFactory.sol";
import "./IGUniPool.sol";
import "./IUniswapPool.sol";
import "./IUniswapPositionManager.sol";
import "./IUniswapV3Router.sol";

/// @title UniMigrator
/// @author Angle Core Team
/// @notice Swaps G-UNI liquidity
contract UniMigrator {
    using SafeERC20 for IERC20;
    address public owner;
    address private constant _AGEUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IGUniRouter private constant _GUNIROUTER = IGUniRouter(0x513E0a261af2D33B46F98b81FED547608fA2a03d);
    IGUniFactory private constant _GUNIFACTORY = IGUniFactory(0xEA1aFf9dbFfD1580F6b81A3ad3589E66652dB7D9);
    address private constant _USDCGAUGE = 0xEB7547a8a734b6fdDBB8Ce0C314a9E6485100a3C;
    address private constant _ETHGAUGE = 0x3785Ce82be62a342052b9E5431e9D3a839cfB581;
    address private constant _GOVERNOR = 0xdC4e6DFe07EFCa50a197DF15D9200883eF4Eb1c8;
    address private constant _UNIUSDCPOOL = 0x7ED3F364668cd2b9449a8660974a26A092C64849;
    address private constant _UNIETHPOOL = 0x9496D107a4b90c7d18c703e8685167f90ac273B0;
    address private constant _GUNIUSDC = 0x2bD9F7974Bc0E4Cb19B8813F8Be6034F3E772add;
    address private constant _GUNIETH = 0x26C2251801D2cfb5461751c984Dc3eAA358bdf0f;
    address private constant _ETHNEWPOOL = 0x8dB1b906d47dFc1D84A87fc49bd0522e285b98b9;
    IUniswapPositionManager private constant _UNI = IUniswapPositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address private constant _UNIROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @notice Constructs a new CompSaver token
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "wrong caller");
        _;
    }

    /// @notice Changes the minter address
    /// @param owner_ Address of the new owner
    function setOwner(address owner_) external onlyOwner {
        require(owner_ != address(0), "0");
        owner = owner_;
    }

    /// @return poolCreated The address of the pool created for the swap
    function migratePool(
        uint8 gaugeType,
        uint256 amountAgEURMin,
        uint256 amountTokenMin
    ) external onlyOwner returns (address poolCreated) {
        address liquidityGauge;
        address stakingToken;
        uint160 sqrtPriceX96Existing;
        address token;
        if (gaugeType == 1) {
            liquidityGauge = _USDCGAUGE;
            stakingToken = _GUNIUSDC;
            token = _USDC;
            (sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(_UNIUSDCPOOL).slot0();
        } else {
            liquidityGauge = _ETHGAUGE;
            stakingToken = _GUNIETH;
            token = _WETH;
            (sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(_UNIETHPOOL).slot0();
        }
        // Giving allowances: we need it to add and remove liquidity
        IERC20(token).safeApprove(address(_GUNIROUTER), type(uint256).max);
        IERC20(stakingToken).safeApprove(address(_GUNIROUTER), type(uint256).max);
        IERC20(_AGEUR).safeIncreaseAllowance(
            address(_GUNIROUTER),
            type(uint256).max - IERC20(_AGEUR).allowance(address(this), address(_GUNIROUTER))
        );
        // Computing amount to recover
        uint256 amountRecovered = IERC20(stakingToken).balanceOf(liquidityGauge);
        ILiquidityGauge(liquidityGauge).accept_transfer_ownership();
        ILiquidityGauge(liquidityGauge).recover_erc20(stakingToken, address(this), amountRecovered);

        uint256 amountAgEUR;
        uint256 amountToken;
        // Removing all liquidity
        (amountAgEUR, amountToken, ) = _GUNIROUTER.removeLiquidity(
            stakingToken,
            amountRecovered,
            amountAgEURMin,
            amountTokenMin,
            address(this)
        );
        if (gaugeType == 1) {
            // In this case, it's _USDC: we need to create the pool
            _UNI.createAndInitializePoolIfNecessary(_AGEUR, _USDC, 100, sqrtPriceX96Existing);
            poolCreated = _GUNIFACTORY.createManagedPool(_AGEUR, _USDC, 100, 0, -276320, -273470);
        } else {
            // In this other case it's wETH and the pool already exists
            poolCreated = _GUNIFACTORY.createManagedPool(_AGEUR, _WETH, 500, 0, -96120, -69000);
            // We need to put the pool at the right price, we do this assuming UniV2 maths and assuming the 5bp fees
            // can be neglected
            (uint256 newPoolPrice, , , , , , ) = IUniswapV3Pool(_ETHNEWPOOL).slot0();
            uint256 oldPoolSpotPrice = (uint256(sqrtPriceX96Existing) * uint256(sqrtPriceX96Existing) * 1e18) >>
                (96 * 2);
            newPoolPrice = (uint256(newPoolPrice) * uint256(newPoolPrice) * 1e18) >> (96 * 2);
            uint256 xBalance = IERC20(_AGEUR).balanceOf(_ETHNEWPOOL);
            uint256 yBalance = IERC20(_WETH).balanceOf(_ETHNEWPOOL);
            // In this case price ETH/agEUR is lower in the new pool or the price of agEUR per ETH is higher in the new pool:
            // we need to remove agEUR and increase ETH and as such buy agEUR
            if (oldPoolSpotPrice > newPoolPrice) {
                uint256 amountOut = xBalance - _sqrt((xBalance * yBalance) / oldPoolSpotPrice) * 10**9;
                IERC20(_WETH).safeApprove(_UNIROUTER, type(uint256).max);
                uint256 amountIn = IUniswapV3Router(_UNIROUTER).exactOutputSingle(
                    ExactOutputSingleParams(
                        _WETH,
                        _AGEUR,
                        500,
                        address(this),
                        block.timestamp,
                        amountOut,
                        type(uint256).max,
                        0
                    )
                );
                amountAgEUR += amountOut;
                amountToken -= amountIn;
            } else {
                // Need to sell agEUR to increase agEUR in the pool: computing the optimal movement as if in UniV2 and assuming no fees
                uint256 amountIn = _sqrt((xBalance * yBalance) / oldPoolSpotPrice) * 10**9 - xBalance;
                IERC20(_AGEUR).safeApprove(_UNIROUTER, amountIn);

                uint256 amountOut = IUniswapV3Router(_UNIROUTER).exactInputSingle(
                    ExactInputSingleParams(_AGEUR, _WETH, 500, address(this), block.timestamp, amountIn, 0, 0)
                );
                amountAgEUR -= amountIn;
                amountToken += amountOut;
            }
            (newPoolPrice, , , , , , ) = IUniswapV3Pool(_ETHNEWPOOL).slot0();
            // Scale of the sqrtPrice is 10**27: we're checking if we got close enough (first 9 figures should be fine)
            if (newPoolPrice > sqrtPriceX96Existing) {
                require(newPoolPrice - sqrtPriceX96Existing < 1 ether);
            } else require(sqrtPriceX96Existing - newPoolPrice < 1 ether);
        }

        // Transfering ownership of the new pool to the guardian address
        IGUniPool(poolCreated).transferOwnership(0x0C2553e4B9dFA9f83b1A6D3EAB96c4bAaB42d430);

        // Adding liquidity
        _GUNIROUTER.addLiquidity(poolCreated, amountAgEUR, amountToken, amountAgEURMin, amountTokenMin, liquidityGauge);
        uint256 newGUNIBalance = IERC20(poolCreated).balanceOf(liquidityGauge);
        ILiquidityGauge(liquidityGauge).set_staking_token_and_scaling_factor(
            poolCreated,
            (amountRecovered * 10**18) / newGUNIBalance
        );
        ILiquidityGauge(liquidityGauge).commit_transfer_ownership(_GOVERNOR);
        IERC20(token).safeTransfer(_GOVERNOR, IERC20(token).balanceOf(address(this)));
        IERC20(_AGEUR).safeTransfer(_GOVERNOR, IERC20(_AGEUR).balanceOf(address(this)));
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Executes a function
    /// @param to Address to sent the value to
    /// @param value Value to be sent
    /// @param data Call function data
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bool, bytes memory) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = to.call{ value: value }(data);
        return (success, result);
    }
}

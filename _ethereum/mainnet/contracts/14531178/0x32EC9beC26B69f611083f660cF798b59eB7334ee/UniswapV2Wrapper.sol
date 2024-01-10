// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./WrapperBase.sol";
import "./OperationsLib.sol";

//TODO: refund unused part for liquidity

/// @title Uniswap V2 Wrapper
/// @author Cosmin Grigore (@gcosmintech)
/// Can be deployed for:
/// - UniswapV2 (all layers)
/// - Sushiswap (all layers)
/// - Quickswap (Matic)
/// - Sushiswap (Matic)
/// - Dfyn (Matic)
/// - Sushiswap (Arbitrum)
/// - SolarBeam (Moonriver)
/// - Elk Finance (Moonriver)
/// - Huckleberry (Moonriver)
/// - Spookyswap (Fantom)
/// - Spiritswap (Fantom)
contract UniswapV2Wrapper is WrapperBase {
    using SafeERC20 for IERC20;

    ///@notice Router used to perform various DEX operations
    IUniswapV2Router02 public swapRouter;

    ///@notice Factory used in various DEX Operations
    IUniswapV2Factory public factory;

    /// @notice Internal data used only in the add liquidity method
    struct AddLiquidityTemporaryData {
        uint256 _amountADesired;
        uint256 _amountBDesired;
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _usedA;
        uint256 _usedB;
        uint256 _obtainedLP;
        uint256 _deadline;
    }
    /// @notice Internal data used only in the remove liquidity method
    struct RemoveLiquidityTemporaryData {
        uint256 _liquidity;
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _obtainedA;
        uint256 _obtainedB;
        uint256 _deadline;
    }

    constructor(
        address _router,
        address _factory,
        address _dexManager
    ) WrapperBase(_dexManager) {
        require(_router != address(0), "ERR: INVALID ROUTER ADDRESS");
        require(_factory != address(0), "ERR: INVALID FACTORY ADDRESS");
        require(_dexManager != address(0), "ERR: INVALID DEX_MANAGER ADDRESS");
        swapRouter = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
    }

    //-----------------
    //----------------- View methods -----------------
    //-----------------
    /// @notice Returns the amount one would obtain from a swap
    /// @param tokenIn Token in address
    /// @param tokenOut Token to be ontained from swap address
    /// @param amountIn Amount to be used for swap
    /// @return Token out amount
    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes calldata
    ) external payable override noValue returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = swapRouter.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    /// @notice Sets the swap router address
    /// @param _router Swap router address
    function setRouter(address _router) external onlyValidAddress(_router) onlyOwner {
        emit RouterChanged(msg.sender, address(swapRouter), _router);
        swapRouter = IUniswapV2Router02(_router);
    }

    /// @notice Sets the factory address
    /// @param _factory Factory address
    function setFactory(address _factory) external onlyValidAddress(_factory) onlyOwner {
        emit FactoryChanged(msg.sender, address(factory), _factory);
        factory = IUniswapV2Factory(_factory);
    }

    //-----------------
    //----------------- Non-view methods -----------------
    //-----------------
    /// @notice Performs a swap
    /// @param _tokenIn Token A address
    /// @param _tokenOut Token B address
    /// @param _amountsData Token A amount, Min amount for Token B
    /// @param _data AMM specific data
    function swap(
        address _tokenIn,
        address _tokenOut,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external override enforceDexManagerAddress returns (uint256) {
        uint256 deadline = abi.decode(_data, (uint256));
        (uint256 _amount, uint256 _amountOutMin) = abi.decode(_amountsData, (uint256, uint256));

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);
        OperationsLib.safeApprove(_tokenIn, address(swapRouter), _amount);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            _amount,
            _amountOutMin,
            path,
            msg.sender,
            deadline
        );
        emit Swapped(_tokenIn, _tokenOut, _amount, amounts[1]);
        return amounts[1];
    }

    /// @notice Adds liquidity and sends obtained LP & leftovers to sender
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountsData Amount info (amount A, amount B, min amount A, min amount B)
    /// @param _data AMM specific data

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    )
        external
        override
        enforceDexManagerAddress
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AddLiquidityTemporaryData memory tempData;
        (tempData._amountADesired, tempData._amountBDesired, tempData._amountAMin, tempData._amountBMin) = abi.decode(
            _amountsData,
            (uint256, uint256, uint256, uint256)
        );

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), tempData._amountADesired);
        OperationsLib.safeApprove(_tokenA, address(swapRouter), tempData._amountADesired);
        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), tempData._amountBDesired);
        OperationsLib.safeApprove(_tokenB, address(swapRouter), tempData._amountBDesired);

        tempData._deadline = abi.decode(_data, (uint256));
        address recipient = _recipient; // fix stack too deep error
        (tempData._usedA, tempData._usedB, tempData._obtainedLP) = swapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            tempData._amountADesired,
            tempData._amountBDesired,
            tempData._amountAMin,
            tempData._amountBMin,
            recipient,
            tempData._deadline
        );
        emit AddedLiquidity(
            _tokenA,
            _tokenB,
            tempData._amountADesired,
            tempData._amountBDesired,
            tempData._usedA,
            tempData._usedB,
            tempData._obtainedLP
        );
        if (tempData._amountADesired > tempData._usedA) {
            IERC20(_tokenA).safeTransfer(_recipient, tempData._amountADesired - tempData._usedA);
        }
        if (tempData._amountBDesired > tempData._usedB) {
            IERC20(_tokenB).safeTransfer(_recipient, tempData._amountBDesired - tempData._usedB);
        }
        return (tempData._usedA, tempData._usedB, tempData._obtainedLP);
    }

    /// @notice Removes liquidity and sends obtained tokens to sender
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountsData LP amount to be burnt, Min amount for token A, Min amount for token B
    /// @param _data AMM specific data

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        address _recipient,
        bytes calldata _amountsData,
        bytes calldata _data
    ) external override enforceDexManagerAddress returns (uint256, uint256) {
        RemoveLiquidityTemporaryData memory tempData;
        (tempData._liquidity, tempData._amountAMin, tempData._amountBMin) = abi.decode(
            _amountsData,
            (uint256, uint256, uint256)
        );
        tempData._deadline = abi.decode(_data, (uint256));

        address lp = factory.getPair(_tokenA, _tokenB);
        IERC20(lp).safeTransferFrom(_recipient, address(this), tempData._liquidity);
        OperationsLib.safeApprove(lp, address(swapRouter), tempData._liquidity);

        (tempData._obtainedA, tempData._obtainedB) = swapRouter.removeLiquidity(
            _tokenA,
            _tokenB,
            tempData._liquidity,
            tempData._amountAMin,
            tempData._amountBMin,
            _recipient,
            tempData._deadline
        );
        emit RemovedLiquidity(_tokenA, _tokenB, tempData._liquidity, tempData._obtainedA, tempData._obtainedB);
        return (tempData._obtainedA, tempData._obtainedB);
    }
}

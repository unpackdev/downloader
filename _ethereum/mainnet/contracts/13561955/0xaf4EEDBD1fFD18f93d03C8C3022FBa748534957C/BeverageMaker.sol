// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";

interface IFeeSplitExtension {
    function accrueFeesAndDistribute(ISetToken _setToken) external;
}

interface ISetToken is IERC20 {}


// BeverageMaker is MasterChef's left hand and kinda a wizard. He can make beverages from pretty much anything!
// This contract handles "serving up" rewards for xBVRG holders by trading tokens collected from Beverage indices fees for BVRG.
contract BeverageMaker is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory private immutable factory;
    
    address private immutable bar;
    
    address private immutable drink;
    
    address private immutable weth;

    mapping(address => address) private _bridges;

    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogConvert(
        address indexed server,
        address indexed token0,
        uint256 amount0,
        uint256 amountSUSHI
    );

    constructor(
        IUniswapV2Factory _factory,
        address _bar,
        address _drink,
        address _weth
    ) public {
        factory = _factory;
        bar = _bar;
        drink = _drink;
        weth = _weth;
    }

    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != drink && token != weth && token != bridge,
            "Maker: Invalid bridge"
        );
        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally-owned addresses.
        require(msg.sender == tx.origin, "Maker: Must use EOA");
        _;
    }

    function convert(IFeeSplitExtension _feeSplitExtension, ISetToken _setToken) external onlyEOA {
        _convert(_feeSplitExtension, _setToken);
    }

    function convertMultiple(IFeeSplitExtension[] calldata _feeSplitExtensions, ISetToken[] calldata _setTokens) external onlyEOA {
        require(_feeSplitExtensions.length == _setTokens.length, "Must be same length");

        for (uint256 i = 0; i < _setTokens.length; i++) {
            _convert(_feeSplitExtensions[i], _setTokens[i]);
        }
    }

    function _convert(IFeeSplitExtension _beverageFeeSplitExtension, ISetToken _setToken) private {
        // accrue and distribute SetToken fees 
        _beverageFeeSplitExtension.accrueFeesAndDistribute(_setToken);

        address token0 = address(_setToken);
        
        // the fees is transferred to this contract hence reading balance is enough
        uint256 amount0 = IERC20(token0).balanceOf(address(this));

        emit LogConvert(
            msg.sender,
            token0,
            amount0,
            _convertStep(token0, amount0)
        );
    }

    function _convertStep(address token0, uint256 amount0) private returns (uint256 sushiOut) {
        if (token0 == drink) {
            IERC20(token0).safeTransfer(bar, amount0);
            sushiOut = amount0;
        } else if (token0 == weth) {
            sushiOut = _swap(token0, drink, amount0, bar);
        } else {
            address bridge = _bridges[token0];
            if (bridge == address(0)) {
                bridge = weth;
            }
            uint256 amountOut = _swap(token0, bridge, amount0, address(this));
            sushiOut = _convertStep(bridge, amountOut);
        }
    }

    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) private returns (uint256 amountOut) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "BeverageMaker: Cannot convert");

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        
        if (toToken > fromToken) {
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, "");
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, "");
        }
    }
}

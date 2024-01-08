// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";

interface IAlpineWithdraw {
    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface IGoldVeinWithdrawFee {
    function asset() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function withdrawFees() external;
    function removeAsset(address to, uint256 fraction) external returns (uint256 share);
}

// SmelterGoldVein is GoldMiner's left hand and kinda a wizard. He can cook up GoldNugget from pretty much anything!
// This contract handles "serving up" rewards for PlatinumNugget holders by trading tokens collected from Gold Vein fees for GoldNugget.
contract SmelterGoldVein is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory private immutable factory;
    //0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
    address private immutable alchemybench;
    //0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272
    IAlpineWithdraw private immutable alPine;
    //0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
    address private immutable goldnugget;
    //0xc6D69475f115F61B1e8C4e78c20C49201c869DB4
    address private immutable weth;
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    bytes32 private immutable pairCodeHash;
    //0x0cbdd17b1671f32d5dfeb12e26cab06b388cbdf1d3647305adb1ec1fa020b87f

    mapping(address => address) private _bridges;

    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogConvert(
        address indexed server,
        address indexed token0,
        uint256 amount0,
        uint256 amountALP,
        uint256 amountGOLN
    );

    constructor(
        IUniswapV2Factory _factory,
        address _alchemybench,
        IAlpineWithdraw _alPine,
        address _goldnugget,
        address _weth,
        bytes32 _pairCodeHash
    ) public {
        factory = _factory;
        alchemybench = _alchemybench;
        alPine = _alPine;
        goldnugget = _goldnugget;
        weth = _weth;
        pairCodeHash = _pairCodeHash;
    }

    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != goldnugget && token != weth && token != bridge,
            "Smelter: Invalid bridge"
        );
        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally-owned addresses.
        require(msg.sender == tx.origin, "Smelter: Must use EOA");
        _;
    }

    function convert(IGoldVeinWithdrawFee goldveinPair) external onlyEOA {
        _convert(goldveinPair);
    }

    function convertMultiple(IGoldVeinWithdrawFee[] calldata goldveinPair) external onlyEOA {
        for (uint256 i = 0; i < goldveinPair.length; i++) {
            _convert(goldveinPair[i]);
        }
    }

    function _convert(IGoldVeinWithdrawFee goldveinPair) private {
        // update Gold Vein fees for this Smelter contract (`feeTo`)
        goldveinPair.withdrawFees();

        // convert updated Gold Vein balance to Alp shares
        uint256 alpShares = goldveinPair.removeAsset(address(this), goldveinPair.balanceOf(address(this)));

        // convert Alp shares to underlying Gold Vein asset (`token0`) balance (`amount0`) for Smelter
        address token0 = goldveinPair.asset();
        (uint256 amount0, ) = alPine.withdraw(IERC20(token0), address(this), address(this), 0, alpShares);

        emit LogConvert(
            msg.sender,
            token0,
            amount0,
            alpShares,
            _convertStep(token0, amount0)
        );
    }

    function _convertStep(address token0, uint256 amount0) private returns (uint256 goldnuggetOut) {
        if (token0 == goldnugget) {
            IERC20(token0).safeTransfer(alchemybench, amount0);
            goldnuggetOut = amount0;
        } else if (token0 == weth) {
            goldnuggetOut = _swap(token0, goldnugget, amount0, alchemybench);
        } else {
            address bridge = _bridges[token0];
            if (bridge == address(0)) {
                bridge = weth;
            }
            uint256 amountOut = _swap(token0, bridge, amount0, address(this));
            goldnuggetOut = _convertStep(bridge, amountOut);
        }
    }

    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) private returns (uint256 amountOut) {
        (address token0, address token1) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), pairCodeHash))
                )
            );

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

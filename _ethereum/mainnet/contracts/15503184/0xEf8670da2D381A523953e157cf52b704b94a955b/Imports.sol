// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "./MockContract.sol";
import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2ERC20.sol";
import "./IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol" as ISushiswapV2Router;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol" as ISushiswapV2Factory;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol" as ISushiswapV2ERC20;
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";
import "./IUniswapV2Pair.sol";

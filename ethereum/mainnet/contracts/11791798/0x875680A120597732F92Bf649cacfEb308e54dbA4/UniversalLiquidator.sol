// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniversalLiquidator.sol";
import "./ILiquidityDex.sol";

import "./IUniversalLiquidatorRegistry.sol";

/**

  The Universal Liquidator is adapted from Layer, https://github.com/affaxltd/layer
  a great effort from the Harvest community member and builder Affax.

  The work has been modified to suit the specific needs of Harvest strategy and fees liquidation.

*/

contract UniversalLiquidator is Ownable, IUniversalLiquidator {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping(bytes32 => address) public getDex;
  bytes32[] public allDexes;

  address public pathRegistry;

  receive() external payable {}

  function setPathRegistry(address _pathRegistry) public onlyOwner {
    pathRegistry = _pathRegistry;
  }

  function swapTokenOnDEX(
    uint256 amountIn,
    uint256 amountOutMin,
    address target,
    bytes32 dexName,
    address[] memory path
  ) public override {
    require(_dexExists(dexName), "Dex does not exist");
    require(amountIn > 0, "No tokens being swapped");

    IERC20(path[0]).safeTransferFrom(target, address(this), amountIn);

    _swap(amountIn, amountOutMin, target, dexName, path);
  }

  function swapTokenOnMultipleDEXes(
    uint256 amountIn,
    uint256 amountOutMin,
    address target,
    bytes32[] memory dexes,
    address[] memory path
  ) external override returns (uint256) {
    require(dexes.length == path.length - 1, "dexes length does not match path length");

    IERC20(path[0]).safeTransferFrom(target, address(this), amountIn);

    for(uint256 i = 0 ; i < path.length - 1; i++) {
      address[] memory liquidationPath = IUniversalLiquidatorRegistry(pathRegistry).getPath(dexes[i], path[i], path[i+1]);
      _swap(
        IERC20(path[i]).balanceOf(address(this)),
        amountOutMin,
        address(this),
        dexes[i],
        liquidationPath
      );
    }
    require(amountOutMin < IERC20(path[path.length-1]).balanceOf(address(this)), "Didn't obtain more than amountOutMin");
    IERC20(path[path.length-1]).safeTransfer(
      target,
      IERC20(path[path.length-1]).balanceOf(address(this))
    );
  }

  function getAllDexes() public override view returns (bytes32[] memory) {
    uint256 size = 0;
    uint256 index = 0;

    for (index = 0; index < allDexes.length; index++) {
      if (getDex[allDexes[index]] != address(0)) {
        size++;
      }
    }

    bytes32[] memory arr = new bytes32[](size);
    uint256 arrIndex = 0;

    for (index = 0; index < allDexes.length; index++) {
      if (getDex[allDexes[index]] != address(0)) {
        arr[arrIndex] = allDexes[index];
        arrIndex++;
      }
    }

    return arr;
  }

  function addDex(bytes32 name, address dexAddress) public onlyOwner {
    require(!_dexExists(name), "Dex already exists");
    getDex[name] = dexAddress;
    allDexes.push(name);
  }

  function changeDexAddress(bytes32 name, address dexAddress) public onlyOwner {
    require(_dexExists(name), "Dex does not exists");
    getDex[name] = dexAddress;
  }

  function _swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address target,
    bytes32 dexName,
    address[] memory path
  ) internal {
    address dex = getDex[dexName];
    require(dex != address(0), "Dex does not exist");

    IERC20(path[0]).safeApprove(dex, 0);
    IERC20(path[0]).safeApprove(dex, amountIn);

    ILiquidityDex(dex).doSwap(amountIn, minAmountOut, address(this), target, path);

    emit Swap(path[path.length-1], path[0], target, msg.sender, amountIn, minAmountOut);
  }

  function _dexExists(bytes32 name) internal view returns (bool) {
    return getDex[name] != address(0);
  }
}

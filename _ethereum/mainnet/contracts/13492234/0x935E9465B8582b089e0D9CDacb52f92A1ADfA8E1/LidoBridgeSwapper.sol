//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./IZkSync.sol";
import "./IWstETH.sol";
import "./ILido.sol";
import "./ICurvePool.sol";
import "./IERC20.sol";

/**
* Exchanges between ETH and wStETH
* index 0: ETH
* index 1: wStETH
*/
contract LidoBridgeSwapper is ZkSyncBridgeSwapper {

    // The address of the stEth token
    address public immutable stEth;
    // The address of the wrapped stEth token
    address public immutable wStEth;
    // The address of the stEth/Eth Curve pool
    address public immutable stEthPool;
    // The referral address for Lido
    address public immutable lidoReferral;

    constructor(
        address _zkSync,
        address _l2Account,
        address _wStEth,
        address _stEthPool,
        address _lidoReferral
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        wStEth = _wStEth;
        address _stEth = IWstETH(_wStEth).stETH();
        require(_stEth == ICurvePool(_stEthPool).coins(1), "stEth mismatch");
        stEth = _stEth;
        stEthPool = _stEthPool;
        lidoReferral = _lidoReferral;
    }

    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external override returns (uint256 amountOut) {
        require(_indexIn + _indexOut == 1, "invalid indexes");

        if (_indexIn == 0) {
            transferFromZkSync(ETH_TOKEN);
            amountOut = swapEthForStEth(_amountIn);
            transferToZkSync(wStEth, amountOut);
            emit Swapped(ETH_TOKEN, _amountIn, wStEth, amountOut);
        } else {
            transferFromZkSync(wStEth);
            amountOut = swapStEthForEth(_amountIn);
            transferToZkSync(ETH_TOKEN, amountOut);
            emit Swapped(wStEth, _amountIn, ETH_TOKEN, amountOut);
        }
    }

    /**
    * @dev Swaps ETH for wrapped stETH and deposits the resulting wstETH to the ZkSync bridge.
    * First withdraws ETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of ETH to swap.
    */
    function swapEthForStEth(uint256 _amountIn) internal returns (uint256) {
        // swap Eth for stEth on the Lido contract
        ILido(stEth).submit{value: _amountIn}(lidoReferral);
        // approve the wStEth contract to take the stEth
        IERC20(stEth).approve(wStEth, _amountIn);
        // wrap to wStEth and return deposited amount
        return IWstETH(wStEth).wrap(_amountIn);
    }

    /**
    * @dev Swaps wrapped stETH for ETH and deposits the resulting ETH to the ZkSync bridge.
    * First withdraws wrapped stETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of wrapped stETH to swap.
    */
    function swapStEthForEth(uint256 _amountIn) internal returns (uint256) {
        // unwrap to stEth
        uint256 unwrapped = IWstETH(wStEth).unwrap(_amountIn);
        // approve pool
        bool success = IERC20(stEth).approve(stEthPool, unwrapped);
        require(success, "approve failed");
        // swap stEth for ETH on Curve and return deposited amount
        return ICurvePool(stEthPool).exchange(1, 0, unwrapped, getMinAmountOut(unwrapped));
    }
}

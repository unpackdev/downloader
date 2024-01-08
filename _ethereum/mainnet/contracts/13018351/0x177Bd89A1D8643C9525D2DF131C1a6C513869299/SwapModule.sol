// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ISwapModule.sol";
import "./GelatoBytes.sol";

contract SwapModule is ISwapModule {
    function swap(address[] memory _swapActions, bytes[] memory _swapDatas)
        external
        override
    {
        require(
            _swapActions.length == _swapDatas.length,
            "SwapModule.swap: actions length != datas length."
        );

        for (uint256 i; i < _swapActions.length; i++) {
            {
                (bool success, bytes memory returnsData) = _swapActions[i].call(
                    _swapDatas[i]
                );
                if (!success)
                    GelatoBytes.revertWithError(
                        returnsData,
                        "SwapModule.swap: "
                    );
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20Metadata.sol";
import "./CrvBase.sol";

abstract contract Crv3x is CrvBase {
    uint256 public constant N = 3;
    address[N] public coins = [address(0x0), address(0x0), address(0x0)];
    uint256[N] public coinDecimals = [0, 0, 0];

    constructor(
        address _pool,
        address _lp,
        address _gauge
    ) CrvBase(_pool, _lp, _gauge) {
        _init(_pool);
    }

    function _init(address _pool) internal virtual override {
        for (uint256 i = 0; i < N; i++) {
            coins[i] = IStableSwapUnderlying(_pool).coins(i);
            coinDecimals[i] = IERC20Metadata(coins[i]).decimals();
        }
    }
}

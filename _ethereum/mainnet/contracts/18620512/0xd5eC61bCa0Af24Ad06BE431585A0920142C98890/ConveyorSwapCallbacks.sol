// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

import "./PancakeV2Callback.sol";
import "./PancakeV3Callback.sol";
import "./UniswapV2Callback.sol";
import "./UniswapV3Callback.sol";
import "./ConvergenceXCallback.sol";
import "./UniFiCallback.sol";
import "./VerseCallback.sol";
import "./ApeSwapCallback.sol";
import "./LinkSwapCallback.sol";
import "./SakeSwapCallback.sol";
import "./DefiSwapCallback.sol";
import "./KyberSwapV3Callback.sol";
import "./AlgebraCallback.sol";

contract ConveyorSwapCallbacks is
    PancakeV2Callback,
    PancakeV3Callback,
    UniswapV2Callback,
    UniswapV3Callback,
    ConvergenceXCallback,
    UniFiCallback,
    VerseCallback,
    ApeSwapCallback,
    LinkSwapCallback,
    SakeSwapCallback,
    DefiSwapCallback,
    KyberSwapV3Callback,
    AlgebraCallback
{}
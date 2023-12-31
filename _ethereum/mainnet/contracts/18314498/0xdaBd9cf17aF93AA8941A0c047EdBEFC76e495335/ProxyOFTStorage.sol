// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ISyntheticToken.sol";
import "./IProxyOFT.sol";

abstract contract ProxyOFTStorageV1 is IProxyOFT {
    /**
     * @notice The synthetic token contract
     */
    ISyntheticToken internal syntheticToken;
}

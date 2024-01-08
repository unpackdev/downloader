// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Helioswap.sol";
import "./IHelioswap.sol";

interface IHelioswapFactory {
    function pools(
        IERC20 token1,
        IERC20 token2
    ) external view returns (IHelioswap, uint256, uint256, uint256, VirtualBalance.Data[2] memory, VirtualBalance.Data[2] memory);

    function isPool(Helioswap pool) external view returns (bool);
}
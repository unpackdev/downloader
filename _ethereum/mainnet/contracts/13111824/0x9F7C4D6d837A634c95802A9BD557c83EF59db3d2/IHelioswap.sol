// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IERC20.sol";

interface IHelioswap {
    function getReturn(
        IERC20 src,
        IERC20 dst,
        uint256 amount
    ) external view returns (uint256);

    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 result);
}

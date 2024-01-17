// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./IERC20.sol";

interface IOneInchPool {
    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns (uint256 result);
}

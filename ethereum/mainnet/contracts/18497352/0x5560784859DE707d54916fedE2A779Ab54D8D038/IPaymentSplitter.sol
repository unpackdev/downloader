// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./IERC20.sol";

interface IPaymentSplitter {
    function releasable(address account) external view returns (uint256);
    function releasable(IERC20 token, address account) external view returns (uint256);

    function release(address payable account) external;
    function release(IERC20 token, address account) external;
}

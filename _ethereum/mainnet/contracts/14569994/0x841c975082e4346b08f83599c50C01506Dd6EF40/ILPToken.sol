// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";

interface ILPToken is IERC20 {
    function poolId() external view returns (uint256);

    function token() external view returns (address);
}

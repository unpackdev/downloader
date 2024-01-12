// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./SafeERC20.sol";

interface ICrvV3 is IERC20 {
    function minter() external view returns (address);
}

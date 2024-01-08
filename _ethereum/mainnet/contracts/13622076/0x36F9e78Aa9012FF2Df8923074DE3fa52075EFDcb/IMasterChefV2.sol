// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";

interface IMasterChefV2 {
    function lpToken(uint256 pid) external view returns (IERC20 _lpToken);
}

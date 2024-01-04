// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IYERC20 is IERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
    function getPricePerFullShare() external view returns (uint256);
}
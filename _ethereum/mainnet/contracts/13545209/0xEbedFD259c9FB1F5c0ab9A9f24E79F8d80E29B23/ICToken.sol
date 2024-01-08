// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IERC20.sol";

interface ICToken is IERC20 {
    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);
}

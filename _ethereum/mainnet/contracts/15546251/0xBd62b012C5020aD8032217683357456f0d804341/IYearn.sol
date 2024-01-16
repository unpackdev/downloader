// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IYearn {
    function decimals() external view returns (uint8);

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);
}

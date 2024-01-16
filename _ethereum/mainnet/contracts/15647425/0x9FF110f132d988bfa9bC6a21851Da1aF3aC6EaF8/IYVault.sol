// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";


interface IYVault {
    function getPricePerFullShare() external view returns(uint256 price);
    function pricePerShare() external view returns(uint256 price);
    function token() external view returns(IERC20);
}


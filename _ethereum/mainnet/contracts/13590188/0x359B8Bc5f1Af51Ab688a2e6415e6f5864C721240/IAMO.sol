// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IAMO {
    function dollarBalances() external view returns (uint256 frax_val_e18, uint256 collat_val_e18);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface DividendPayingContractInterface {
    function dividendOf(address _owner) external view returns (uint256);

    // function distributeDividends(uint256 _amount) external ;

    // function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

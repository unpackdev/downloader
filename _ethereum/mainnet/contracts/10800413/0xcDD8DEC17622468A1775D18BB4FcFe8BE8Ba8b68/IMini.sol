// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMini {
    function k() external view returns(uint256);
    function kTotals(uint256) external view returns(uint256);
    function issueTo(address to, uint256 amount) external;
}
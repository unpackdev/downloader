// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface INutDistributor {
    function updateVtb(address token, address lender, uint incAmount, uint decAmount) external;
    function inNutDistribution() external view returns(bool);
}

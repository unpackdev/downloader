// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IFlyzBondingCalculator {
    function valuation(address _LP, uint256 _amount)
        external
        view
        returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

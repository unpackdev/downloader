// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ISyncusCalculator {
    function valuation(
        address pair_,
        uint amount_
    ) external view returns (uint _value);

    function valuationEther(uint amount_) external view returns (uint _value);

    function markdown(address _pair) external view returns (uint);
}

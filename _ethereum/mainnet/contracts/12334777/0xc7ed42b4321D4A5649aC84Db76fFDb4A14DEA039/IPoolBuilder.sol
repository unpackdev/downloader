// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

interface IPoolBuilder {
    function buildPool(
        address _controller,
        address _derivativeVault,
        address _feeCalculator,
        address _repricer,
        uint _baseFee,
        uint _maxFee,
        uint _feeAmp
    ) external returns(address);
}

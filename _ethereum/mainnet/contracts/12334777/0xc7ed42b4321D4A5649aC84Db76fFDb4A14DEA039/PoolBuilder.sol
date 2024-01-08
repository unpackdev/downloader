// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import "./Pool.sol";
import "./IPoolBuilder.sol";

contract PoolBuilder is IPoolBuilder{
    function buildPool(
        address _controller,
        address _derivativeVault,
        address _feeCalculator,
        address _repricer,
        uint _baseFee,
        uint _maxFee,
        uint _feeAmp
    ) public override returns(address){
        Pool pool = new Pool(
            _derivativeVault,
            _feeCalculator,
            _repricer,
            _baseFee,
            _maxFee,
            _feeAmp,
            _controller
        );
        pool.transferOwnership(msg.sender);
        return address(pool);
    }
}

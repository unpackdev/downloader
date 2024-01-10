// SPDZ-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PRBMathUD60x18.sol";

/// @title  The Math Library
///
/// @author Test-in-Prod.
///
/// @notice The library with useful and handy mathematical functionalities.
///
library Math {

    using PRBMathUD60x18 for uint256;

    /// @notice Computation of square roots using Babylonian method.
    ///
    ///         The algorithm cannot overflow. Thus, the use of SafeMath is not considered.
    ///
    /// @param  _s  The input
    /// @return _x  The output
    ///
    function sqrt(uint256 _s) internal pure returns (uint256 _x) {
        _x = _s;
        uint256 t = _s / 2 + 1;
        while(t < _x) {
            _x = t;
            t = (_s / t + t) / 2;
        }
    }

    function exp(uint256 _base, uint256 _power) internal pure returns (uint256 _out) {
        _out = _base.powu(_power);
        /*_out = 1 ether;
        while(_power > 0) {
            if(_power % 2 == 1) {
                _power--;
                _out *= _base;
                _out /= 1 ether;
            }
            _power /= 2;
            _base *= _base;
            _base /= 1 ether;
        }*/
    }

    function log2(uint256 _in) internal pure returns (uint256 _out) {
        _out = _in.log2();
    }
}

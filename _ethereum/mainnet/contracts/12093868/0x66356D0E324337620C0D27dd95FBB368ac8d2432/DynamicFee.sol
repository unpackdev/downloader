// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Num.sol";
import "./IDynamicFee.sol";

contract DynamicFee is IDynamicFee, Bronze, Num {

    function spow3(int _value)
    internal pure
    returns(int){
        return ((_value * _value) / iBONE) * _value / iBONE;
    }

    function calcExpStart(
        int _inBalance,
        int _outBalance
    )
    internal pure
    returns(int) {
        return (_inBalance - _outBalance) * iBONE / (_inBalance + _outBalance);
    }

    function calcSpotFee(
        int _expStart,
        uint _baseFee,
        uint _feeAmp,
        uint _maxFee
    )
    external pure override
    returns(uint) {
        if(_expStart >= 0) {
            return min(_baseFee + _feeAmp * uint(_expStart * _expStart) / BONE, _maxFee);
        } else {
            return _baseFee / 2;
        }
    }

    function calc(
        int[3] memory _inRecord,
        int[3] memory _outRecord,
        int _baseFee,
        int _feeAmp,
        int _maxFee
    )
    external pure override
    returns(int fee, int expStart)
    {

        expStart = calcExpStart(_inRecord[0], _outRecord[0]);
        int _expEnd = (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE /
            (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if(expStart >= 0) {
            fee = _baseFee + ((_feeAmp) * (spow3(_expEnd) - spow3(expStart))) * iBONE / (3 * (_expEnd - expStart));
        } else if(_expEnd <= 0) {
            fee = _baseFee / 2;
        } else {
            fee = calcExpEndFee(
                _inRecord,
                _outRecord,
                _baseFee,
                _feeAmp,
                _expEnd
            );
        }

        if(_maxFee <  fee) {
            fee = _maxFee;
        }

        if(iBONE / 1000 >  fee) {
            fee = iBONE / 1000;
        }
    }

    function calcExpEndFee(
        int[3] memory _inRecord,
        int[3] memory _outRecord,
        int _baseFee,
        int _feeAmp,
        int _expEnd
    )
        internal
        pure
        returns (int)
    {
        int inBalanceLeveraged = getLeveragedBalance(_inRecord[0], _inRecord[1]);
        int tokenAmountIn1 = inBalanceLeveraged * (_outRecord[0] - _inRecord[0]) * iBONE /
        (inBalanceLeveraged + getLeveragedBalance(_outRecord[0], _outRecord[1])) / iBONE;
        int inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int tokenAmountIn2 = inBalanceLeveragedChanged * (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE /
        (inBalanceLeveragedChanged + ((getLeveragedBalance(_outRecord[0], _outRecord[1]) - _outRecord[2] * iBONE))) / iBONE;

        int fee = tokenAmountIn1 * _baseFee / (iBONE * 2);
        fee = fee + tokenAmountIn2 * (_baseFee + _feeAmp * (_expEnd * _expEnd / iBONE) / 3) / iBONE;
        return fee * iBONE / (tokenAmountIn1 + tokenAmountIn2);
    }

    function getLeveragedBalance(
        int _balance,
        int _leverage
    )
    internal pure
    returns(int)
    {
        return _balance * _leverage;
    }
}

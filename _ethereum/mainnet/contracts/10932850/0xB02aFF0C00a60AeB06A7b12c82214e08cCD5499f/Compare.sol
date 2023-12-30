pragma solidity ^0.6.2;

import "./DSMath.sol";

contract Compare is DSMath {
    
    function getbytes(string memory _data) public view returns(bytes memory result) {
        result = bytes(_data);
    } 
    
    function compareBytes(bytes memory _a, bytes memory _b) public view returns(bool same) {
        
        same = true;
        
        same = _a.length == _b.length;
        if(!same) {
            return same;
        }
        
        for(uint i = 0; i< _a.length; i++) { // compare each bytes32
            same = same && _a[i] == _b[i];
            if (!same) {
                return same;
            }
        }
    }

    function equalUint(uint _a, uint _b) public view returns(bool) {
        return _a == _b;
    }

    function gteUint(uint _a, uint _b) public view returns(bool) {
        return _a >= _b;
    }

    function gtUint(uint _a, uint _b) public view returns(bool) {
        return _a > _b;
    }
    function substraction(uint _a, uint _b) public view returns(uint) {
        return sub(_a, _b);
    }
}
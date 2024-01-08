// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract VaccineClaimSnapshot {
    mapping(address => uint8) _snapshot;
    address[] _snapshotAddresses = [
        0xeD051Fe098F973c518c7BEf3325e3a890B1A2237,
        0x88E5FAE699aE1e31A25Df304CD20f1F6DaF8f5B5,
        0xdE98445B4148dbe540308eB9FC40c0CDD3318Ef8,
        0x3ECad9B41fC71840f3362441A397Ab24ab3450Fc,
        0x052F2567Da498C06dC591Ac48e0B56a07b28Bba2,
        0x87A11A1F2E117F6cD2CE68498cae6d2170788406,
        0x5d2846a7f10b56A3582A6f7B9E5f06A939BE3C89,
        0xFC10b8CDa9f09531A2C4c4f5f5ac269B4CFBB907,
        0x0466C648A159d535686FcAaDCd5cD9987B5e08f0,
        0x34E46bD7a1b00D42b5A409B6EC310982C09d0D9D,
        0x70976032911f0cEF0c9e121A6563F21c9C52B2fa,
        0xCeaaa873AE4CD40140C6aa9107cd2aa1Db890B3b,
        0xf50848Eb4125e5151aC4a9f648Cb9E99Bf179b12
    ];
    
    constructor () {
        for (uint i = 0; i < _snapshotAddresses.length; i++) {
            _snapshot[_snapshotAddresses[i]] = 1;
        }
        _snapshot[msg.sender] = 1;  // to test that claim is working and import a collection to opensea
    }
    
    function howManyFreeTokensForAddress(address target) public view returns (uint8) {
        return _snapshot[target];
    }
    
    function _cannotClaimAnymore(address target) internal {
        _snapshot[target] = 0;
    }
}
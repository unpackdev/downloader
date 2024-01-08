// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

struct DelegateMapView {    
    bytes32 functionId;
    address otherParty;        
    bool mustRelinquish;
    bool pending;
}

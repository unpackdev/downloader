// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

interface IDelegateRegistry {
    
    function delegation(address delegator, bytes32 id) external view returns(address);

    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
    
}
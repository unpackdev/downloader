// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./DelegateMapView.sol";

interface IDelegateFunction {
    
    struct AllowedFunctionSet {
        bytes32 id;
        bool allowed;
    }    

    struct DelegateMap {    
        bytes32 functionId;
        address otherParty;        
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }
    
    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    function getDelegation(address from, bytes32 functionId) external view returns (DelegateMapView memory map);

    function delegate(DelegateMap[] calldata sets) external;

    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    function removeDelegation(bytes32[] calldata functionIds) external;

    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}
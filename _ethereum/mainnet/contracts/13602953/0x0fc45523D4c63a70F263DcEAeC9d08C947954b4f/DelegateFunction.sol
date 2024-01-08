// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./IDelegateFunction.sol";
import "./EventSender.sol";
import "./DelegationDisabled.sol";
import "./DelegationEnabled.sol";

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract DelegateFunction is IDelegateFunction, Initializable, Ownable, Pausable, EventSender {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeMath for uint256;

    EnumerableSet.Bytes32Set private allowedFunctions;

    //from => functionId => (otherParty, mustRelinquish, functionId)    
    mapping(address => mapping(bytes32 => Destination)) private delegations;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    function getDelegations(address from) external override view returns (DelegateMapView[] memory maps) {        
        uint256 numOfFunctions = allowedFunctions.length();
        maps = new DelegateMapView[](numOfFunctions);
        for(uint256 ix = 0; ix < numOfFunctions; ix++) {
            bytes32 functionId = allowedFunctions.at(ix);
            Destination memory existingDestination = delegations[from][functionId];
            if (existingDestination.otherParty != address(0)) {                
                maps[ix] = DelegateMapView({
                    functionId: functionId,
                    otherParty: existingDestination.otherParty,
                    mustRelinquish: existingDestination.mustRelinquish,
                    pending: existingDestination.pending
                });
            }
        }
    }

    function getDelegation(address from, bytes32 functionId) external override view returns (DelegateMapView memory map) {
        Destination memory existingDestination = delegations[from][functionId];
        map = DelegateMapView({
                functionId: functionId,
                otherParty: existingDestination.otherParty,
                mustRelinquish: existingDestination.mustRelinquish,
                pending: existingDestination.pending
          });        
    }

    function delegate(DelegateMap[] calldata sets) external override whenNotPaused {
        uint256 length = sets.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            DelegateMap calldata set = sets[ix];
            address from = msg.sender;

            require(allowedFunctions.contains(set.functionId), "INVALID_FUNCTION");
            require(set.otherParty != address(0), "INVALID_DESTINATION");
            require(set.otherParty != from, "NO_SELF");

            //Remove any existing delegation
            Destination memory existingDestination = delegations[from][set.functionId];
            if (existingDestination.otherParty != address(0)) {     
                _removeDelegation(from, set.functionId, existingDestination);
            }

            delegations[from][set.functionId] = Destination({
                otherParty: set.otherParty,
                mustRelinquish: set.mustRelinquish,
                pending: true
            });
            
            emit PendingDelegationAdded(from, set.otherParty, set.functionId, set.mustRelinquish);            
        }       
    }

    function acceptDelegation(DelegatedTo[] calldata incoming) external override whenNotPaused {
        uint256 length = incoming.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            DelegatedTo calldata deleg = incoming[ix];
            Destination storage destination = delegations[deleg.originalParty][deleg.functionId];
            require(destination.otherParty == msg.sender, "NOT_ASSIGNED");
            require(destination.pending, "ALREADY_ACCEPTED");

            destination.pending = false;

            bytes memory data = abi.encode(DelegationEnabled({
                eventSig: "DelegationEnabled",
                from: deleg.originalParty, 
                to: msg.sender, 
                functionId: deleg.functionId
            }));

            sendEvent(data);

            emit DelegationAccepted(deleg.originalParty, msg.sender, deleg.functionId, destination.mustRelinquish);
        }
    }

    function removeDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            Destination memory existingDestination = delegations[msg.sender][functionIds[ix]];
            _removeDelegation(msg.sender, functionIds[ix], existingDestination);
        }
    }

    function rejectDelegation(DelegatedTo[] calldata rejections) external override whenNotPaused {
        uint256 length = rejections.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            DelegatedTo memory pending = rejections[ix];
            _rejectDelegation(msg.sender, pending);
        }
    }

    function relinquishDelegation(DelegatedTo[] calldata relinquish) external override whenNotPaused {
        uint256 length = relinquish.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            _relinquishDelegation(msg.sender, relinquish[ix]);
        }
    }

    function cancelPendingDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            _cancelPendingDelegation(msg.sender, functionIds[ix]);
        }
    }

    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external override onlyOwner {
        uint256 length = functions.length;
        require(functions.length > 0, "NO_DATA");

        for(uint256 ix = 0; ix < length; ix++) {
            if (functions[ix].allowed) {
                allowedFunctions.add(functions[ix].id);
            } else {
                allowedFunctions.remove(functions[ix].id);
            }
        }

        emit AllowedFunctionsSet(functions);
    }

    function canControlEventSend() internal override view returns (bool) {
        return msg.sender == owner();
    }

    function _rejectDelegation(address to, DelegatedTo memory pending) private {
        Destination memory existingDestination = delegations[pending.originalParty][pending.functionId];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(existingDestination.pending, "ALREADY_ACCEPTED");
        
        delete delegations[pending.originalParty][pending.functionId];

        emit DelegationRejected(pending.originalParty, to, pending.functionId, existingDestination.mustRelinquish);
    }

    function _removeDelegation(address from, bytes32 functionId, Destination memory existingDestination) private {
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(!existingDestination.mustRelinquish, "EXISTING_MUST_RELINQUISH");

        delete delegations[from][functionId];

        if (existingDestination.pending) {
            emit PendingDelegationRemoved(from, existingDestination.otherParty, functionId, existingDestination.mustRelinquish);
        } else {

            _sendDisabledEvent(from, existingDestination.otherParty, functionId);

            emit DelegationRemoved(from, existingDestination.otherParty, functionId, existingDestination.mustRelinquish);
        }
    }

    function _relinquishDelegation(address to, DelegatedTo calldata relinquish) private {
        Destination memory existingDestination = delegations[relinquish.originalParty][relinquish.functionId];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(!existingDestination.pending, "NOT_YET_ACCEPTED");

        delete delegations[relinquish.originalParty][relinquish.functionId];

        _sendDisabledEvent(relinquish.originalParty, to, relinquish.functionId);

        emit DelegationRelinquished(relinquish.originalParty, to, relinquish.functionId, existingDestination.mustRelinquish);
    }

    function _sendDisabledEvent(address from, address to, bytes32 functionId) private {
        bytes memory data = abi.encode(DelegationDisabled({
            eventSig: "DelegationDisabled",
            from: from,
            to: to, 
            functionId: functionId
        }));

        sendEvent(data);
    }

    function _cancelPendingDelegation(address from, bytes32 functionId) private {
        require(allowedFunctions.contains(functionId), "INVALID_FUNCTION");
                    
        Destination memory existingDestination = delegations[from][functionId];
        require(existingDestination.otherParty != address(0), "NO_PENDING");
        require(existingDestination.pending, "NOT_PENDING");

        delete delegations[from][functionId];
        
        emit PendingDelegationRemoved(from, existingDestination.otherParty, functionId, existingDestination.mustRelinquish);
    }
}
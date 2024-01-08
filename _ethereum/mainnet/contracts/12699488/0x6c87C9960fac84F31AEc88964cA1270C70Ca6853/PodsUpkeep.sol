// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMathUpgradeable.sol";

import "./AddressRegistry.sol";

import "./IPod.sol";
import "./KeeperCompatibleInterface.sol";

/// @notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of a registry of Pod contracts
contract PodsUpkeep is KeeperCompatibleInterface, Ownable, Pausable {

    using SafeMathUpgradeable for uint256;
    
    /// @notice Address of the registry of pods contract which require upkeep
    AddressRegistry public podsRegistry;

    /// @dev Fixed length of the last upkeep block number (multiple this by 8 to get the maximum number of pods for storage)
    uint8 constant PODS_PACKED_ARRAY_SIZE = 10;

    uint256[PODS_PACKED_ARRAY_SIZE] internal lastUpkeepBlockNumber;

    /// @notice Global upkeep interval expressed in blocks at which pods.batch() will be called
    uint256 public upkeepBlockInterval;    

    /// @notice Emitted when the upkeep block interval is updated
    event UpkeepBlockIntervalUpdated(uint upkeepBlockInterval);

    /// @notice Emitted when the upkeep max batch is updated
    event UpkeepBatchLimitUpdated(uint upkeepBatchLimit);
    
    /// @notice Emitted when the address registry is updated
    event PodsRegistryUpdated(AddressRegistry addressRegistry);

    /// @notice Maximum number of pods that performUpkeep can be called on
    uint256 public upkeepBatchLimit;

    /// @notice Contract Constructor. No initializer. 
    constructor(AddressRegistry _podsRegistry, address _owner, uint256 _upkeepBlockInterval, uint256 _upkeepBatchLimit) Ownable() {
        
        podsRegistry = _podsRegistry;
        emit PodsRegistryUpdated(_podsRegistry);

        transferOwnership(_owner);
        
        upkeepBlockInterval = _upkeepBlockInterval;
        emit UpkeepBlockIntervalUpdated(_upkeepBlockInterval);

        upkeepBatchLimit = _upkeepBatchLimit;
        emit UpkeepBatchLimitUpdated(_upkeepBatchLimit);
    }

    /// @notice Updates a 256 bit word with a 32 bit representation of a block number at a particular index
    /// @param _existingUpkeepBlockNumbers The 256 word
    /// @param _podIndex The index within that word (0 to 7)
    /// @param _value The block number value to be inserted
    function _updateLastBlockNumberForPodIndex(uint256 _existingUpkeepBlockNumbers, uint8 _podIndex, uint32 _value) internal pure returns (uint256) { 

        uint256 mask =  (type(uint32).max | uint256(0)) << (_podIndex * 32); // get a mask of all 1's at the pod index    
        uint256 updateBits =  (uint256(0) | _value) << (_podIndex * 32); // position value at index with 0's in every other position

        /* 
        (updateBits | ~mask) 
            negation of the mask is 0's at the location of the block number, 1's everywhere else
            OR'ing it with updateBits will give 1's everywhere else, block number intact
        
        (_existingUpkeepBlockNumbers | mask)
            OR'ing the exstingUpkeepBlockNumbers with mask will give maintain other blocknumber, put all 1's at podIndex
        
            finally AND'ing the two halves will filter through 1's if they are supposed to be there
        */
        return (updateBits | ~mask) & (_existingUpkeepBlockNumbers | mask); 
    }

    /// @notice Takes a 256 bit word and 0 to 7 index within and returns the uint32 value at that index
    /// @param _existingUpkeepBlockNumbers The 256 word
    /// @param _podIndex The index within that word
    function _readLastBlockNumberForPodIndex(uint256 _existingUpkeepBlockNumbers, uint8 _podIndex) internal pure returns (uint32) { 
  
        uint256 mask =  (type(uint32).max | uint256(0)) << (_podIndex * 32);
        return uint32((_existingUpkeepBlockNumbers & mask) >> (_podIndex * 32));
    }

    /// @notice Get the last Upkeep block number for a pod
    /// @param podIndex The position of the pod in the Registry
    function readLastBlockNumberForPodIndex(uint256 podIndex) public view returns (uint32) {
        
        uint256 wordIndex = podIndex / 8;
        return _readLastBlockNumberForPodIndex(lastUpkeepBlockNumber[wordIndex], uint8(podIndex % 8));
    }

    /// @notice Checks if Pods require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) override external view returns (bool upkeepNeeded, bytes memory performData) {
        
        if(paused()) return (false, performData);   

        address[] memory pods = podsRegistry.getAddresses();
        uint256 _upkeepBlockInterval = upkeepBlockInterval;
        uint256 podsLength = pods.length;

        for(uint256 podWord = 0; podWord <= podsLength / 8; podWord++){

            uint256 _lastUpkeep = lastUpkeepBlockNumber[podWord]; // this performs the SLOAD
            for(uint256 i = 0; i + (podWord * 8) < podsLength; i++){
                
                uint32 podLastUpkeepBlockNumber = _readLastBlockNumberForPodIndex(_lastUpkeep, uint8(i));
                if(block.number > podLastUpkeepBlockNumber + _upkeepBlockInterval){
                    return (true, "");
                }
            }
        }       
        return (false, "");    
    }

    /// @notice Performs upkeep on the pods contract and updates lastUpkeepBlockNumbers
    /// @param performData Not used in this implementation.
    function performUpkeep(bytes calldata performData) override external whenNotPaused{
    
        address[] memory pods = podsRegistry.getAddresses();
        uint256 podsLength = pods.length;
        uint256 _batchLimit = upkeepBatchLimit;
        uint256 batchesPerformed = 0;

        for(uint8 podWord = 0; podWord <= podsLength / 8; podWord++){ // give word index
            
            uint256 _updateBlockNumber = lastUpkeepBlockNumber[podWord]; // this performs the SLOAD

            for(uint8 i = 0; i + (podWord * 8) < podsLength; i++){ // pod index within word
                
                if(batchesPerformed >= _batchLimit) {
                    break;
                }
                // get the 32 bit block number from the 256 bit word
                uint32 podLastUpkeepBlockNumber = _readLastBlockNumberForPodIndex(_updateBlockNumber, i);
                if(block.number > podLastUpkeepBlockNumber + upkeepBlockInterval) {
                    IPod(pods[i + (podWord * 8)]).drop();
                    batchesPerformed++;
                    // updated pod's most recent upkeep block number and store update to that 256 bit word
                    _updateBlockNumber = _updateLastBlockNumberForPodIndex(_updateBlockNumber, i, uint32(block.number));                   
                }
            }         
            lastUpkeepBlockNumber[podWord] = _updateBlockNumber; // update the entire 256 bit word at once
        }
    }

    /// @notice Updates the upkeepBlockInterval. Can only be called by the contract owner
    /// @param _upkeepBlockInterval The new upkeepBlockInterval (in blocks)
    function updateBlockUpkeepInterval(uint256 _upkeepBlockInterval) external onlyOwner {
        upkeepBlockInterval = _upkeepBlockInterval;
        emit UpkeepBlockIntervalUpdated(_upkeepBlockInterval);
    }

    /// @notice Updates the upkeep max batch. Can only be called by the contract owner
    /// @param _upkeepBatchLimit The new _upkeepBatchLimit
    function updateUpkeepBatchLimit(uint256 _upkeepBatchLimit) external onlyOwner {
        upkeepBatchLimit = _upkeepBatchLimit;
        emit UpkeepBatchLimitUpdated(_upkeepBatchLimit);
    }

    /// @notice Updates the address registry. Can only be called by the contract owner
    /// @param _addressRegistry The new podsRegistry
    function updatePodsRegistry(AddressRegistry _addressRegistry) external onlyOwner {
        podsRegistry = _addressRegistry;
        emit PodsRegistryUpdated(_addressRegistry);
    }

    /// @notice Pauses the contract. Only callable by owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}
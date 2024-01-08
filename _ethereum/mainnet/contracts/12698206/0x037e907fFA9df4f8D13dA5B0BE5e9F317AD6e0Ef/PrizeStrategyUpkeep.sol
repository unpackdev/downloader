// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./KeeperCompatibleInterface.sol";
import "./PeriodicPrizeStrategyInterface.sol";
import "./PrizePoolRegistryInterface.sol";
import "./PrizePoolInterface.sol";
import "./SafeAwardable.sol";

import "./AddressRegistry.sol";
import "./Ownable.sol";
import "./Pausable.sol";

///@notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of PrizePools in the associated registry. 
contract PrizeStrategyUpkeep is KeeperCompatibleInterface, Ownable, Pausable {

    /// @notice Ensures the target address is a prize strategy (has both canStartAward and canCompleteAward)
    using SafeAwardable for address;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    AddressRegistry public prizePoolRegistry;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    /// @dev Set accordingly to prevent out-of-gas transactions during calls to performUpkeep
    uint256 public upkeepBatchSize;

    /// @notice Stores the last upkeep block number
    uint256 public upkeepLastUpkeepBlockNumber;

    /// @notice Stores the minimum block interval between permitted performUpkeep() calls
    uint256 public upkeepMinimumBlockInterval;

    /// @notice Emitted when the upkeepBatchSize has been changed
    event UpkeepBatchSizeUpdated(uint256 upkeepBatchSize);

    /// @notice Emitted when the prize pool registry has been changed
    event UpkeepPrizePoolRegistryUpdated(AddressRegistry prizePoolRegistry);

    /// @notice Emitted when the Upkeep Minimum Block interval is updated
    event UpkeepMinimumBlockIntervalUpdated(uint256 upkeepMinimumBlockInterval);

    /// @notice Emitted when the Upkeep has been performed
    event UpkeepPerformed(uint256 startAwardsPerformed, uint256 completeAwardsPerformed);


    constructor(AddressRegistry _prizePoolRegistry, uint256 _upkeepBatchSize, uint256 _upkeepMinimumBlockInterval) public Ownable() {
        prizePoolRegistry = _prizePoolRegistry;
        emit UpkeepPrizePoolRegistryUpdated(_prizePoolRegistry);

        upkeepBatchSize = _upkeepBatchSize;
        emit UpkeepBatchSizeUpdated(_upkeepBatchSize);

        upkeepMinimumBlockInterval = _upkeepMinimumBlockInterval;
        emit UpkeepMinimumBlockIntervalUpdated(_upkeepMinimumBlockInterval);
    }


    /// @notice Checks if PrizePools require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {

        if(block.number < upkeepLastUpkeepBlockNumber + upkeepMinimumBlockInterval){
            return (false, performData);
        }
        
        address[] memory prizePools = prizePoolRegistry.getAddresses();

        // check if canStartAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canStartAward()){
                return (true, performData);
            } 
        }
        // check if canCompleteAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canCompleteAward()){
                return (true, performData);
            } 
        }
        return (false, performData);
    }
    
    /// @notice Performs upkeep on the prize pools. 
    /// @param performData Not used in this implementation.
    function performUpkeep(bytes calldata performData) external override whenNotPaused {

        uint256 _upkeepLastUpkeepBlockNumber = upkeepLastUpkeepBlockNumber; // SLOAD
        require(block.number > _upkeepLastUpkeepBlockNumber + upkeepMinimumBlockInterval, "PrizeStrategyUpkeep::minimum block interval not reached");

        address[] memory prizePools = prizePoolRegistry.getAddresses();

      
        uint256 batchCounter = upkeepBatchSize; //counter for batch

        uint256 poolIndex = 0;
        uint256 startAwardCounter = 0;
        uint256 completeAwardCounter = 0;

        uint256 updatedUpkeepBlockNumber;

        while(batchCounter > 0 && poolIndex < prizePools.length){
            
            address prizeStrategy = PrizePoolInterface(prizePools[poolIndex]).prizeStrategy();
            
            if(prizeStrategy.canStartAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).startAward();
                startAwardCounter++;
                batchCounter--;
            }
            else if(prizeStrategy.canCompleteAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).completeAward();       
                completeAwardCounter++;
                batchCounter--;
            }
            poolIndex++;            
        }
        
        if(startAwardCounter > 0 || completeAwardCounter > 0){
            updatedUpkeepBlockNumber = block.number;
        }

        // update if required
        if(_upkeepLastUpkeepBlockNumber != updatedUpkeepBlockNumber){
            upkeepLastUpkeepBlockNumber = updatedUpkeepBlockNumber; //SSTORE
            emit UpkeepPerformed(startAwardCounter, completeAwardCounter);
        }
  
    }


    /// @notice Updates the upkeepBatchSize which is set to prevent out of gas situations
    /// @param _upkeepBatchSize Amount upkeepBatchSize will be set to
    function updateUpkeepBatchSize(uint256 _upkeepBatchSize) external onlyOwner {
        upkeepBatchSize = _upkeepBatchSize;
        emit UpkeepBatchSizeUpdated(_upkeepBatchSize);
    }


    /// @notice Updates the prize pool registry
    /// @param _prizePoolRegistry New registry address
    function updatePrizePoolRegistry(AddressRegistry _prizePoolRegistry) external onlyOwner {
        prizePoolRegistry = _prizePoolRegistry;
        emit UpkeepPrizePoolRegistryUpdated(_prizePoolRegistry);
    }


    /// @notice Updates the upkeep minimum interval blocks
    /// @param _upkeepMinimumBlockInterval New upkeepMinimumBlockInterval
    function updateUpkeepMinimumBlockInterval(uint256 _upkeepMinimumBlockInterval) external onlyOwner {
        upkeepMinimumBlockInterval = _upkeepMinimumBlockInterval;
        emit UpkeepMinimumBlockIntervalUpdated(_upkeepMinimumBlockInterval);
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



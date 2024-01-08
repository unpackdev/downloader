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

///@notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of PrizePools in the associated registry. 
contract PrizeStrategyUpkeep is KeeperCompatibleInterface, Ownable {

    /// @notice Ensures the target address is a prize strategy (has both canStartAward and canCompleteAward)
    using SafeAwardable for address;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    AddressRegistry public prizePoolRegistry;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    /// @dev Set accordingly to prevent out-of-gas transactions during calls to performUpkeep
    uint256 public upkeepBatchSize;

    /// @notice Emitted when the upkeepBatchSize has been changed
    event UpkeepBatchSizeUpdated(uint256 upkeepBatchSize);

    /// @notice Emitted when the prize pool registry has been changed
    event UpkeepPrizePoolRegistryUpdated(AddressRegistry prizePoolRegistry);


    constructor(AddressRegistry _prizePoolRegistry, uint256 _upkeepBatchSize) Ownable() public {
        prizePoolRegistry = _prizePoolRegistry;
        emit UpkeepPrizePoolRegistryUpdated(_prizePoolRegistry);

        upkeepBatchSize = _upkeepBatchSize;
        emit UpkeepBatchSizeUpdated(_upkeepBatchSize);
    }


    /// @notice Checks if PrizePools require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) view override external returns (bool upkeepNeeded, bytes memory performData) {

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
    function performUpkeep(bytes calldata performData) override external {

        address[] memory prizePools = prizePoolRegistry.getAddresses();

        uint256 batchCounter = upkeepBatchSize; //counter for batch
        uint256 poolIndex = 0;
        
        while(batchCounter > 0 && poolIndex < prizePools.length){
            
            address prizeStrategy = PrizePoolInterface(prizePools[poolIndex]).prizeStrategy();
            
            if(prizeStrategy.canStartAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).startAward();
                batchCounter--;
            }
            else if(prizeStrategy.canCompleteAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).completeAward();
                batchCounter--;
            }
            poolIndex++;            
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

}



pragma solidity ^0.8.4;

import "./IUniftyGovernanceConsumer.sol";

interface IUniftyGovernance{

    /**
     * Returns the current epoch number.
     * */
    function epoch() external returns(uint256);
    
    /**
     * Returns the overall grantable $UNT left in the governance contract.
     * */
    function grantableUnt() external returns(uint256);
    
    /**
     * Can only be called by a registered consumer and _amount cannot exceed the granted $UNT
     * as per current emission rate.
     * */
    function mintUnt(uint256 _amount) external;
    
    /**
     * Returns the account info for the given 
     * _account parameters:
     * 
     * ( 
     *  IUniftyGovernanceConsumer consumer,
     *  address peer,  
     *  uint256 allocationTime,
     *  uint256 unstakableFrom,
     *  uint256 amount
     * )
     * */
    function accountInfo(address _account) external view returns(IUniftyGovernanceConsumer, address, uint256, uint256, uint256);
    
    /**
     * Returns the consumer info for the given _consumer.
     * 
     * (
     *  uint256 grantStartTime,
     *  uint256 grantRateSeconds,
     *  uint256 grantSizeUnt,
     *  address[] peers
     * )
     * 
     * */
    function consumerInfo(IUniftyGovernanceConsumer _consumer) external view returns(uint256, uint256, uint256, address[] calldata, string[] calldata);
    
    /**
     * Returns the amount of accounts allocating to the given _peer of _consumer.
     * */
    function nifAllocationLength(IUniftyGovernanceConsumer _consumer, address _peer) external view returns(uint256);
    
    /**
     * Returns the currently available $UNT for the given _consumer.
     * */
    function earnedUnt(IUniftyGovernanceConsumer _consumer) external view returns(uint256);
    
    /**
     * Returns true if the governance is pausing. And fals if not.
     * It is recommended but not mandatory to take this into account in your own implemenation.
     * */
    function isPausing() external view returns(bool);
    
    /**
     * The amount of $NIF being allocated to the given _peer of _consumer.
     * */
    function consumerPeerNifAllocation(IUniftyGovernanceConsumer _consumer, address _peer) external view returns(uint256);
}

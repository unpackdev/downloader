// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./LinkTokenInterface.sol";

import "./Counters.sol";

/*
* @title Contract for Pixelvault draws using Chainlink VRF V2 
*
* @author Niftydude
*/
contract PixelvaultDraws is VRFConsumerBaseV2, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint64 public subscriptionId;
    
    mapping(uint256 => Draw) public draws;

    struct Draw {
        uint256 snapshotEntries;
        uint256 amountOfWinners;        
        uint256 randomNumber;
        bool isFulfilled;
        bool allowDuplicates;
        string entryListIpfsHash;
        string description;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {        
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_linkToken);

        keyHash = _keyHash;
    }   

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }    

    /**
    * @notice return all winning entries for a given draw
    * 
    * @param drawId the giveaway id to return winners for
    */
    function getWinners(uint256 drawId) external view returns (uint256[] memory) {
        uint256 snapshotEntries = draws[drawId].snapshotEntries;
        uint256 amountOfWinners = draws[drawId].amountOfWinners;        

        require(draws[drawId].isFulfilled, "GetWinners: draw not fulfilled");        

        uint256[] memory expandedValues = new uint256[](amountOfWinners);
        bool[] memory isNumberPicked = new bool[](snapshotEntries);

        uint256 resultIndex;
        uint256 i;
        while (resultIndex < amountOfWinners) {
            uint256 number = (uint256(keccak256(abi.encode(draws[drawId].randomNumber, i))) % snapshotEntries) + 1;
            
            if(draws[drawId].allowDuplicates || !isNumberPicked[number-1]) {
                expandedValues[resultIndex] = number;
                isNumberPicked[number-1] = true;

                resultIndex++;
            }
            i++;
        }

        return expandedValues;
    }

    /**
    * @notice initiate a new draw
    * 
    * @param _snapshotEntries the number of entries in the snapshot
    * @param _amountOfWinners the amount of winners to pick
    * @param _entryListIpfsHash ipfs hash pointing to the list of entries
    * @param _allowDuplicates if true, a single entry is allowed to win multiple times
    * 
    */
    function startDraw(
        uint256 _snapshotEntries, 
        uint256 _amountOfWinners, 
        string memory _entryListIpfsHash, 
        bool _allowDuplicates,
        string memory _description
    ) external onlyOwner returns (uint256 requestId) {
        require(counter.current() == 0 || draws[counter.current()-1].isFulfilled, "Draw: previous draw not fulfilled");    

        Draw storage d = draws[counter.current()];
        d.snapshotEntries = _snapshotEntries;
        d.amountOfWinners = _amountOfWinners;
        d.entryListIpfsHash = _entryListIpfsHash;
        d.allowDuplicates = _allowDuplicates;
        d.description = _description;

        counter.increment();

        uint256 s_requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          1
        );

        return s_requestId;
    }    

    /**
    * @notice emergency function to force fulfillment
    * 
    * @param _drawId the id of the giveaway to fulfill
    */
    function forceFulfill(uint256 _drawId) external onlyOwner {
        draws[_drawId].isFulfilled = true;
    }                    

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        draws[counter.current()-1].randomNumber = randomWords[0];
        draws[counter.current()-1].isFulfilled = true;        
    }    
   
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";

/*
 * @title Random Number Integer Generator Contract
 * @notice This contract fetches verified random numbers which can then be used offchain 
 */


/**
* @dev Data required to create the random number for a given VFR request
*/
struct RandomNumberRequested {
    uint minValue; // minimum value of the random number (inclusive)
    uint maxValue; // maximum value of the random number (inclusive)
    string title; // reason for the random number request
    uint randomWords; // response value from VRF
}

contract RandomNumberParallel is VRFConsumerBaseV2, Ownable {
    // Chainlink Parameters
    VRFCoordinatorV2Interface internal COORDINATOR;
    LinkTokenInterface internal LINKTOKEN;

    uint64 internal s_subscriptionId = 17; // mainnet
    address internal vrfCoordinator =
    0x271682DEB8C4E0901D1a1550aD2e64D568E69909;  // mainnet
    address internal link = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // mainnet
    bytes32 internal keyHash =
    0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // mainnet

    //uint64 internal s_subscriptionId = 6133; // rinkeby
    //address internal vrfCoordinator =
    //0x6168499c0cFfCaCD319c818142124B7A15E857ab; // rinkeby
    //bytes32 internal keyHash =
    //0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;  // rinkeby
    //address internal link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // rinkeby

    uint32 internal callbackGasLimit = 2000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public allRandomNumbers;
    mapping(uint => uint) public blockToRandomNumber;
    mapping(uint => RandomNumberRequested) public requestIdToRandomNumberMetaData;

    event RandomNumberGenerated(
        uint randomNumber, 
        uint256 chainlinkRequestId,
        string title);

    constructor(
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
    }
    
    /*
     * @notice request a random integer within given bounds
     * @param _minValue - minimum value of the random number (inclusive)
     * @param _maxValue - maximum value of the random number (inclusive)
     * @param _title - reason for the random number request
     * @return requestID - id of the request rng for chainlink response
     */
    function requestRandomWords(
        uint _minValue,
        uint _maxValue,
        string memory _title
    ) public onlyOwner returns (uint256 requestID) {
        requestID = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        RandomNumberRequested storage newRng = requestIdToRandomNumberMetaData[requestID];
        newRng.minValue = _minValue;
        newRng.maxValue = _maxValue;
        newRng.title = _title;
    }

    // callback function called by chainlink
    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
    internal
    override
    {
        // get the random number
        uint randomRange = requestIdToRandomNumberMetaData[requestID].maxValue + 1 - 
        requestIdToRandomNumberMetaData[requestID].minValue;
        uint randomNumber = randomWords[0] % randomRange;
        randomNumber = randomNumber + requestIdToRandomNumberMetaData[requestID].minValue;
        requestIdToRandomNumberMetaData[requestID].randomWords = randomWords[0];

        require(blockToRandomNumber[block.number] == 0, "already fetched random for this block");

        blockToRandomNumber[block.number] = randomWords[0];
        emit RandomNumberGenerated(randomNumber, requestID, requestIdToRandomNumberMetaData[requestID].title);
        allRandomNumbers.push(randomWords[0]);
    }
}